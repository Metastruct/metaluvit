local util = require('./util')
local User = require('./user')
local Modes = require('./modes')
local Channel = require('core').Emitter:extend()

function Channel:initialize(connection, name, modes, topic)
	self.connection = connection
	self.name = name
	self.identifier = self:identifier()
	self.users = {}
	self.modes = modes or {}
	self.topic = topic or ""
	self.eventhandlers = {}

	self.eventhandlers.mode = function(channel, setby, modes, params)
		if self:is(channel) then
			Modes.apply(self, setby, modes, params)
		end
	end
	self.eventhandlers.topic = function(channel, topic, setby)
		if self:is(channel) and topic ~= self.topic then
			local oldtopic = self.topic
			self.topic = topic
			self:emit("topic", oldtopic, self.topic)
		end
	end
	self.eventhandlers.join = function(channel, whojoined)
		if self:is(channel) then
			local user = self:adduser(whojoined)
			if user ~= nil then
				self:emit("join", user, reason)
			end
		end
	end
	self.eventhandlers.part = function(channel, wholeft, reason)
		if self:is(channel) then
			local user = self:getuser(wholeft)
			if user ~= nil then
				self:removeuser(user)
				self:emit("part", user, reason)
			end
		end
	end
	self.eventhandlers.kick = function(channel, kicked, kickedby, reason)
		if self:is(channel) then
			local user = self:getuser(kicked)
			if user ~= nil then
				self:removeuser(user)
				self:emit("kick", user, kickedby, reason)
			end
		end
	end
	self.eventhandlers.quit = function(nick, reason)
		local user = self:getuser(nick)
		if user ~= nil then
			self:removeuser(user)
			self:emit("quit", user, reason)
		end
	end
	self.eventhandlers.kill = function(nick)
		local user = self:getuser(nick)
		if user ~= nil then
			self:removeuser(user)
			self:emit("kill", user)
		end
	end
	self.eventhandlers.nick = function(oldnick, newnick)
		local user = self:getuser(oldnick)
		if user ~= nil then
			user.nick = newnick
			self:removeuser(user)
			self:setuser(newnick, user)
			self:emit("nick", user, oldnick)
		end
	end
	self:_addhandlers()
end

function Channel:destroy()
	self:_removehandlers()
	self:removeAllListeners()
end

function Channel:_addhandlers()
	for event, callback in pairs(self.eventhandlers) do
		self.connection:on(event, callback)
	end
end

function Channel:_removehandlers()
	for event, callback in pairs(self.eventhandlers) do
		self.connection:removeListener(event, callback)
	end
end

function Channel:adduser(nick_or_user)
	local nick = type(nick_or_user) == "string" and nick_or_user or nick_or_user.nick
	return self:setuser(nick_or_user, User:new(self, nick))
end

function Channel:removeuser(nick_or_user)
	return self:setuser(nick_or_user, nil)
end

function Channel:setuser(nick_or_user, user)
	local nick = type(nick_or_user) == "string" and nick_or_user or nick_or_user.nick
	self.users[nick] = user
	return user
end

function Channel:getuser(nick_or_user)
	local nick = type(nick_or_user) == "string" and nick_or_user or nick_or_user.nick
	return self.users[nick]
end

function Channel:hasuser(nick_or_user)
	return self:getuser(nick_or_user) ~= nil
end

function Channel:identifier(channelname)
	if type(self) == "string" then
		channelname = self
	elseif self ~= Channel then
		channelname = self.name 
	end
	return channelname:lower()
end

function Channel:is(other)
	if self == other then return true end
	local other_identifier = type(other) == "table" and other.identifier or other:lower()
	return self.identifier == other_identifier
end

function Channel.meta.__tostring(self)
	return self.name
end

return Channel