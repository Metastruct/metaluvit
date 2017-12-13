local util = require('./util')
local table = require "table"
local string = require "string"
local MAX_MESSAGE_SIZE = require "./constants".MAX_MESSAGE_SIZE

local IRCMessage = require('core').Object:extend()

function IRCMessage:initialize(command, ...)
	self.command = command
	self.args = {...}
end

function IRCMessage:clone()
	return IRCMessage:new(self.command, unpack(self.args))
end

function IRCMessage:lastarg()
	return self.args[#self.args]
end

local function get_and_discard_matches(str, pattern, max_matches)
	local matches = {str:match(pattern)}
	if matches[1] ~= nil then
		while max_matches and #matches > max_matches do
			table.remove(matches)
		end
		return str:gsub(pattern, "", max_matches), unpack(matches)
	else
		return str, nil
	end
end

function IRCMessage:size()
	-- str + \r\n
	return tostring(self):len() + 2
end

function IRCMessage:toservermsg(connection)
	local servermsg = self:clone()
	servermsg.nick = connection.nick
	servermsg.host = connection.host or string.rep("x", 63) -- maximum size of a hostname
	servermsg.user = connection.user or string.rep("x", 16) -- approximation of the length of a username
	return servermsg
end

function IRCMessage:serversize(connection)
	return self:toservermsg(connection):size()
end

function IRCMessage:serverstring(connection)
	return tostring(self:toservermsg(connection))
end

function IRCMessage:trimtosize(connection)
	local spillovermsg = nil
	local size = self:serversize(connection)
	if size > MAX_MESSAGE_SIZE then
		local lastarg = self:lastarg()
		local lastarg_size = lastarg:len()
		local sizeavailable = MAX_MESSAGE_SIZE - (size - lastarg_size)
		local trimmed = lastarg:sub(1, sizeavailable)
		local lastwordbreak = trimmed:find("[^%w]%w-$")
		local finaltrimpoint = lastwordbreak or sizeavailable
		trimmed = trimmed:sub(1, finaltrimpoint)
		local excess = lastarg:sub(finaltrimpoint+1)
		self.args[#self.args] = trimmed
		spillovermsg = self:clone()
		spillovermsg.args[#spillovermsg.args] = excess
	end
	return spillovermsg
end

function IRCMessage:fromstring(line)
	if type(self) ~= "table" or self == IRCMessage then
		if not line then line = self end
		self = IRCMessage:new()
	end
	line, self.prefix = get_and_discard_matches(line, "^:([^ ]+) +", 1)
	if self.prefix ~= nil then
		local raw_prefix = self.prefix
		local valid_nick_pattern = "^([_a-zA-Z0-9%[%]\\`^{}|-]*)$"
		raw_prefix, self.host = get_and_discard_matches(raw_prefix, "@(.*)$")
		raw_prefix, self.user = get_and_discard_matches(raw_prefix, "!(.*)$")
		if raw_prefix:match(valid_nick_pattern) then
			self.nick = raw_prefix
		else
			self.server = raw_prefix
		end
	end
	line, self.command = get_and_discard_matches(line, "^([^ ]+) *", 1)
	local raw_args = util.string.split(line, " ")
	for i,arg in ipairs(raw_args) do
		if arg ~= "" then
			if arg:sub(0,1) == ":" then
				local rest = util.table.slice(raw_args, i)
				local joined = util.string.join(rest, " ")
				joined = joined:sub(2)
				table.insert(self.args, joined)
				break
			end
			table.insert(self.args, arg)
		end
	end
	return self
end

function IRCMessage.meta.__tostring(self)
	local str = ""
	if self.server then
		str = str..":"..self.server.." "
	elseif self.nick then
		str = str..":"..self.nick..(self.user and "!"..self.user or "")..(self.host and "@"..self.host or "").." "
	end
	str = str..self.command
	if #self.args > 0 then
		if self.args[#self.args] == "" or self.args[#self.args]:find("%s") ~= nil then
			if #self.args > 1 then
				local middle_args = util.table.slice(self.args, 1, -1)
				str = str.." "..util.string.join(middle_args, " ")
			end
			str = str.." :"..self.args[#self.args]
		else
			str = str.." "..util.string.join(self.args, " ")
		end
	end
	return str
end

return IRCMessage