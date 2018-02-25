local instanceof = require('core').instanceof
local Emitter = require('core').Emitter
local dns = require('dns')
local net = require('net')
local table = require('table')
local os = require('os')
local tls = require('tls')
local string = require('string')
local Timer = require('timer')
local util = require('./lib/util')
local Message = require('./lib/message')
local Channel = require('./lib/channel')
local Modes = require('./lib/modes')
local Constants = require('./lib/constants')
local CTCP = Constants.CTCP
local Handlers = require('./lib/handlers')
local Queue = require('./lib/queue')

local IRC = Emitter:extend()

function IRC:initialize(server, nick, options)
	self.server = server
	self.nick = nick
	self.options = options or {}
	util.table.fallback(self.options, {
		port = 6667,
		ssl = false,
		real_name = self.nick,
		username = self.nick,
		password = nil,
		invisible = false,
		max_retries = 99,
		retry_delay = 2000,
		auto_connect = false,
		auto_retry = true,
		auto_join = {},
		auto_rejoin = true,
		flood_protection = true,
	})
	self.sock = nil
	self.buffer = ""
	self.connected = false
	self.connecting = false
	self.channels = {}
	self.current_channels = {}
	self.channel_prefixes = {}
	self.retrycount = 0
	self.retrytask = nil
	self.intentionaldisconnect = false
	self.sendqueue = Queue:new(self)

	if self.options.auto_connect then
		self:connect()
	end

	self:on("ikick", function(channel, kickedby, reason)
		if self.options.auto_rejoin then
			self:join(channel.name)
		end
	end)
	self:on("connect", function(welcomemsg)
		-- get our own user info if we don't already have it
		self:send(Message:new("WHOIS", self.nick))
		-- auto join channels on connect
		for channel_or_i,channel_or_key in pairs(self.options.auto_join) do
			if type(channel_or_i) == "string" then
				self:join(channel_or_i, channel_or_key)
			else
				self:join(channel_or_key)
			end
		end
	end)
end

function IRC:connect(num_retries)
	if num_retries ~= nil then
		if self.connected then
			return
		end
		self.retrycount = num_retries
		print("Connect retry #"..self.retrycount.." to "..self.server)
	end

	if self.connected then
		self:disconnect("Reconnecting")
	end

	self:_setupconnection()
end

function IRC:say(target, text)
	if target == "#" then
		for channelid,channel in pairs(self.current_channels) do
			self:say(channel.name, text)
		end
		return
	end
	local lines = util.string.split(text, "[\r\n]+")
	if lines[#lines] == "" then table.remove(lines) end
	for _,line in ipairs(lines) do
		self:send(Message:new("PRIVMSG", target, line))
	end
end

function IRC:notice(target, text)
	self:send(Message:new("NOTICE", target, text))
end

function IRC:action(target, text)
	self:say(target, self:_toctcp("ACTION", text))
end

function IRC:join(channels, keys)
	channels = type(channels) == "table" and util.string.join(channels, ",") or channels
	keys = type(keys) == "table" and util.string.join(keys, ",") or keys
	self:send(Message:new("JOIN", channels, keys))
end

function IRC:part(channels, message)
	channels = type(channels) == "table" and util.string.join(channels, ",") or channels
	self:send(Message:new("PART", channels, message))
end

function IRC:disconnect(reason)
	self.intentionaldisconnect = true
	if self.connected then
		self:_send(Message:new("QUIT", reason))
	end
	self:_disconnected(reason or "Quit")
end

function IRC:names(channels)
	channels = type(channels) == "table" and util.string.join(channels, ",") or channels
	self:send(Message:new("NAMES", channels))
end

function IRC:floodprotection(enabled)
	self.options.flood_protection = enabled
end

function IRC:ping()
	self:_send(Message:new("PING", self.server))
end

function IRC:send(msg)
	local msgs = {msg}
	repeat
		local spillovermsg = msgs[#msgs]:trimtosize(self)
		table.insert(msgs, spillovermsg)
	until spillovermsg == nil

	for _,msg in ipairs(msgs) do
		self.sendqueue:push(msg)
	end
end

function IRC:_send(msg, callback)
	self:write(tostring(msg).."\r\n", callback)
end

function IRC:write(data, callback)
	if self.sock then
		self.sock:write(data, callback)
	end
end

function IRC:close()
	if not self.sock then return end
	if self.sock.socket then
		self.sock.socket:close() -- SSL
	else
		self.sock:close() -- TCP
	end
end

function IRC:ischannel(channelname)
	return type(channelname) == "string" and util.table.contains(self.channel_prefixes, channelname:sub(1, 1))
end

function IRC:getchannel(channelname)
	local identifier = Channel.identifier(channelname)
	if self.channels[identifier] == nil then
		self.channels[identifier] = Channel:new(self, channelname)
	end
	return self.channels[identifier]
end

function IRC:is_in_channel(channelname)
	local identifier = Channel.identifier(channelname)
	return self.current_channels[identifier] ~= nil
end

function IRC:isme(nick)
	return self.nick == nick
end

function IRC:_setupconnection()
	self.intentionaldisconnect = false
	self.connecting = true
	self.sendqueue:clear()

	if self.retrytask ~= nil then
		Timer.clearTimer(self.retrytask)
	end

	dns.resolve4(self.server, function (err, addresses)
		local resolvedip
		for _,a in ipairs(addresses) do
			if a.address then
				resolvedip = a.address
				break
			end
		end
		if not resolvedip then
			self:_disconnected("Could not resolve address for "..tostring(self.server), err, false)
			return
		end
		if self.options.ssl then
			local options = {host=resolvedip, port=self.options.port}
			self.sock = tls.connect (options, function()
				self:_handlesock(self.sock)
				self:_connect(self.nick, resolvedip)
			end)
			self.sock:on('error', function(...)
				assert(false, ...)
			end)
		else
			self.sock = net.createConnection(self.options.port, resolvedip, function(err)
				if err then assert(err) end
				self:_handlesock(self.sock)
				self:_connect(self.nick, resolvedip)
			end)
		end
	end)
end

function IRC:_handlesock(sock)
	sock:on("data", function (data)
		local lines = self:_splitlines(data)
		for i = 1, #lines do
			local line = lines[i]
			local msg = self:_parsemsg(line)
			self:_handlemsg(msg)
			self:emit("data", line)
		end
	end)
	sock:on("error", function (err)
		self:_disconnected(err.message, err)
	end)
	sock:on("close", function (...)
		self:_disconnected("Socket closed", ...)
	end)
	sock:on("end", function (...)
		self:_disconnected("Socket ended", ...)
	end)
end

function IRC:_connect(nick, ip)
	if self.options.password ~= nil then
		self:send(Message:new("PASS", self.options.password))
	end
	self:send(Message:new("NICK", nick))
	local username = self.options.username or nick
	local modeflag = self.options.invisible and 8 or 0
	local unused_filler = "*"
	local real_name = self.options.real_name
	self:send(Message:new("USER", username, modeflag, unused_filler, real_name))
	self:emit("connecting", nick, self.server, username, real_name)
end

function IRC:_connected(welcomemsg, server)
	assert(not self.connected)
	self.retrycount = 0
	self.connecting = false
	self.connected = true
	self:_clearchannels()
	self.sendqueue:start()
	Modes.clear()
	self:emit("connect", welcomemsg, server, self.nick)
end

function IRC:_disconnected(reason, err, shouldretry)
	if shouldretry == nil then shouldretry = true end
	local was_connected = self.connected
	local was_connecting = self.connecting
	self.connected = false
	self.connecting = false
	self.sendqueue:clear()
	if was_connected or was_connecting then
		self:emit(was_connected and "disconnect" or "connecterror", reason, err)

		if self:_shouldretry() and shouldretry then
			self.retrytask = Timer.setTimeout(self.options.retry_delay, function() 
				self:connect(self.retrycount+1)
			end)
		end
	end
end

function IRC:_shouldretry()
	return not self.intentionaldisconnect and self.options.auto_retry and self.retrycount < self.options.max_retries
end

function IRC:_toctcp(type, text)
	return CTCP.DELIM..type.." "..text..CTCP.DELIM
end

function IRC:_isctcp(text)
	return text:len() > 2 and text:sub(1,1) == CTCP.DELIM and text:sub(-1) == CTCP.DELIM
end

function IRC:_nickchanged(oldnick, newnick)
	if oldnick == newnick then return end
	if self:isme(oldnick) then
		self:emit("inick", oldnick, newnick)
		self.nick = newnick
	else
		self:emit("nick", oldnick, newnick)
	end
end

function IRC:_addchannel(channelname)
	assert(self:ischannel(channelname))
	assert(not self:is_in_channel(channelname))
	local identifier = Channel.identifier(channelname)
	self.current_channels[identifier] = self:getchannel(channelname)
end

function IRC:_removechannel(channelname)
	assert(self:is_in_channel(channelname))
	local identifier = Channel.identifier(channelname)
	self.current_channels[identifier] = nil
end

function IRC:_clearchannels()
	for identifier, channel in pairs(self.current_channels) do
		self:_removechannel(channel.name)
	end
end

function IRC:_splitlines(rawlines)
	assert(type(rawlines) == "string")
	self.buffer = self.buffer..rawlines
	local lines = util.string.split(self.buffer, "\r\n")
	self.buffer = table.remove(lines)
	return lines
end

function IRC:_parsemsg(line)
	assert(type(line) == "string")
	return Message:fromstring(line)
end

function IRC:_handlemsg(msg)
	if type(msg) == "string" then
		msg = self:_parsemsg(msg)
	end
	assert(instanceof(msg, Message), type(msg))

	if Handlers[msg.command] then
		Handlers[msg.command](self, msg)
	else
		self:emit("unhandled", msg)
	end
end

IRC.Formatting = require('./lib/formatting')
IRC.Message = require('./lib/message')
IRC.Channel = require('./lib/channel')
IRC.Constants = require('./lib/constants')
IRC.User = require('./lib/user')
IRC.Handlers = require('./lib/handlers')
IRC.Modes = require('./lib/modes')
IRC.SendQueue = require('./lib/queue')
IRC.User = require('./lib/user')

return IRC
