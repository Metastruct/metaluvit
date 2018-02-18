local Object = require "core".Object
local Timer = require "timer"
local table = require "table"
local string = require "string"

local Queue = Object:extend()

function Queue:initialize(connection, transferlimit)
	self.connection = connection
	self.queue = {}
	self.burstlimit = 4
	self.send_interval = 2200
	self.available_sends = self.burstlimit
	self.enabled = true
end

function Queue:disable()
	self.enabled = false
	self:stop()
end

function Queue:enable()
	self.enabled = true
end

function Queue:stop()
	if self.sendtask then
		Timer.clearInterval(self.sendtask)
	end
end

function Queue:start()
	self:stop()

	if self.enabled then
		self.sendtask = Timer.setInterval(self.send_interval, function()
			if self.connection.options.flood_protection then
				self:new_send_available()
				self:process()
			end
		end)
	end
end

function Queue:push(msg)
	table.insert(self.queue, msg)
	self:process()
end

function Queue:pop()
	return table.remove(self.queue, 1)
end

function Queue:clear()
	self.queue = {}
	self.available_sends = self.burstlimit
end

function Queue:isready()
	return #self.queue > 0
end

function Queue:peek()
	return self.queue[1]
end

function Queue:peeksize()
	local peekmsg = self:peek()
	return peekmsg and peekmsg:size() or 0
end

function Queue:cansend()
	return self.available_sends > 0 or not self.connection.options.flood_protection
end

function Queue:new_send_available()
	if self.available_sends < self.burstlimit then
		self.available_sends = self.available_sends + 1
	end
end

function Queue:process()
	while self:isready() and self:cansend() do
		local msg = self:pop()
		self.connection:_send(msg)
		if self.connection.options.flood_protection then
			self.available_sends = self.available_sends - 1
		end
	end
end

return Queue