local table = require "table"
local string = require "string"
local util = require "./util"
local Modes = require "./modes"
local Message = require "./message"
local Constants = require "./constants"
local RPL = Constants.RPL
local ERR = Constants.ERR

local IGNORE = function() end

local Handlers = {}

Handlers["PING"] = function(irc, msg)
	irc:send(Message:new("PONG", unpack(msg.args)))
	irc:emit("ping", unpack(msg.args))
end
Handlers["PONG"] = function(irc, msg)
	irc:emit("pong", unpack(msg.args))
end
Handlers["ERROR"] = function(irc, msg)
	irc:_disconnected(msg:lastarg())
end

Handlers["PRIVMSG"] = function(irc, msg)
	local from = msg.nick
	local to = msg.args[1]
	local text = #msg.args >= 2 and msg.args[2] or ""
	if not irc:_isctcp(text) then
		if irc:isme(to) then
			irc:emit("pm", from, text)
		else
			irc:emit("message", from, to, text)
		end
	else
		-- TODO: handle ctcp
	end
end
Handlers["NOTICE"] = function(irc, msg)
	local from = msg.nick
	local to = msg.args[1]
	local text = #msg.args > 1 and msg.args[2] or ""
	irc:emit("notice", from, to, text)
end
Handlers["NICK"] = function(irc, msg)
	local oldnick = msg.nick
	local newnick = msg.args[1]
	irc:_nickchanged(oldnick, newnick)
end
Handlers["MODE"] = function(irc, msg)
	local setby = msg.nick
	local channelname_or_username = msg.args[1]
	local modes = msg.args[2]
	local params = util.table.slice(msg.args, 3)
	if irc:ischannel(channelname_or_username) then
		local channel = irc:getchannel(channelname_or_username)
		irc:emit("mode", channelname_or_username, setby, modes, params)
	else
		irc:emit("usermode", channelname_or_username, setby, modes, params)
	end
end
Handlers["INVITE"] = function(irc, msg)
	local from = msg.nick
	local to = msg.args[1]
	local channel = msg.args[2]
	irc:emit("invite", channel, from)
end
Handlers["JOIN"] = function(irc, msg)
	local whojoined = msg.nick
	local channelname = msg.args[1]
	if irc:isme(whojoined) then
		irc:_addchannel(channelname)
		irc:emit("ijoin", irc:getchannel(channelname))
	else
		local channel = irc:getchannel(channelname)
		irc:emit("join", channel, whojoined)
	end
end
Handlers["PART"] = function(irc, msg)
	local wholeft = msg.nick
	local channelname = msg.args[1]
	local reason = #msg.args >= 2 and msg.args[2] or nil
	local channel = irc:getchannel(channelname)
	if irc:isme(wholeft) then
		irc:_removechannel(channelname)
		irc:emit("ipart", channel, reason)
	else
		irc:emit("part", channel, wholeft, reason)
	end
end
Handlers["KICK"] = function(irc, msg)
	local kickedby = msg.nick
	local channelname = msg.args[1]
	local kicked = msg.args[2]
	local reason = #msg.args >= 3 and msg.args[3] or nil
	local channel = irc:getchannel(channelname)
	if irc:isme(kicked) then
		irc:_removechannel(channelname)
		irc:emit("ikick", channel, kickedby, reason)
	else
		irc:emit("kick", channel, kicked, kickedby, reason)
	end
end
Handlers["QUIT"] = function(irc, msg)
	local whoquit = msg.nick
	local reason = msg.args[1]
	if irc:isme(whoquit) then
		irc:emit("iquit", reason)
		irc:_disconnected("Quit: "..reason)
	else
		irc:emit("quit", whoquit, reason)
	end
end
Handlers["KILL"] = function(irc, msg)
	local killed = msg.args[1]
	if irc:isme(killed) then
		irc:emit("ikill", killed)
		irc:_disconnected("Killed by the server")
	else
		irc:emit("kill", killed)
	end
end

-- topic
Handlers["TOPIC"] = function(irc, msg)
	local setby = msg.nick
	local channel = msg.args[1]
	local topic = msg.args[2]
	irc:emit("topic", channel, topic, setby)
end
Handlers[RPL.TOPIC] = function(irc, msg)
	local to = msg.args[1]
	local channelname = msg.args[2]
	local topic = msg.args[3]
	irc:emit("topic", channelname, topic, nil)
end
Handlers[RPL.NOTOPIC] = Handlers[RPL.TOPIC]

-- whois
Handlers[RPL.WHOISUSER] = function(irc, msg)
	local to = msg.args[1]
	local nick = msg.args[2]
	local user = msg.args[3]
	local host = msg.args[4]
	local unused = msg.args[5]
	local realname = msg.args[6]
	if irc:isme(nick) then
		irc.host = host
		irc.user = user
	end
	-- TODO: handle other users
end
-- TODO: handle other whois replies

-- names
Handlers[RPL.NAMREPLY] = function(irc, msg)
	local to = msg.args[1]
	local channeltype = msg.args[2]
	local channelname = msg.args[3]
	local users = util.string.split(msg.args[4], " ")
	local channel = irc:getchannel(channelname)
	for _,nick in ipairs(users) do
		local mode = Modes.getmodebyprefix(nick:sub(1,1))
		if mode ~= nil then
			nick = nick:sub(2)
		end
		channel:adduser(nick)
		if mode ~= nil then
			mode:set(channel, nil, {nick})
		end
	end
end
Handlers[RPL.ENDOFNAMES] = function(irc, msg)
	local to = msg.args[1]
	local channelname = msg.args[2]
	local text = msg.args[3]
	local channel = irc:getchannel(channelname)
	irc:emit("names", channel)
end

-- connecting
Handlers[RPL.WELCOME] = function(irc, msg)
	local actualnick = msg.args[1]
	irc:_nickchanged(irc.nick, actualnick)
	irc:_connected(msg:lastarg(), msg.server)
end
Handlers[ERR.NICKNAMEINUSE] = function(irc, msg)
	-- TODO: better handling of nickname in use/more options
	irc.nick = irc.nick.."_"
	irc:send(Message:new("NICK", irc.nick))
end
Handlers[RPL.YOURHOST] = IGNORE
Handlers[RPL.CREATED] = IGNORE
Handlers[RPL.LUSERCLIENT] = IGNORE
Handlers[RPL.LUSEROP] = IGNORE
Handlers[RPL.LUSERUNKNOWN] = IGNORE
Handlers[RPL.LUSERCHANNELS] = IGNORE
Handlers[RPL.LUSERME] = IGNORE
Handlers[RPL.LOCALUSERS] = IGNORE
Handlers[RPL.GLOBALUSERS] = IGNORE
Handlers[RPL.STATSDLINE] = IGNORE
-- TODO: Handle RPL.MYINFO (a fallback for RPL.ISUPPORT?)
Handlers[RPL.ISUPPORT] = function(irc, msg)
	for i,arg in ipairs(msg.args) do
		local key, value = arg:match("^([A-Z]+)=?(.*)$")
		if key == "CHANMODES" then
			local flagsbytype = util.string.split(value, ",")
			for flagtype, flagsstring in ipairs(flagsbytype) do
				flags = util.string.split(flagsstring, "")
				for _,flag in ipairs(flags) do
					Modes.add(flag, flagtype)
				end
			end
		elseif key == "PREFIX" then
			local flagsstring, prefixesstring = value:match("^%((.*)%)(.*)$")
			local flags = util.string.split(flagsstring, "")
			local prefixes = util.string.split(prefixesstring, "")
			assert(#flags==#prefixes)
			for i,flag in ipairs(flags) do
				Modes.add(flag, Modes.MODETYPE_USERPREFIX, prefixes[i])
			end
		elseif key == "CHANTYPES" then
			irc.channel_prefixes = {}
			for letter in value:gmatch(".") do 
				table.insert(irc.channel_prefixes, letter) 
			end
		end
	end
end

-- motd
Handlers[RPL.MOTDSTART] = function(irc, msg)
	irc.motd = msg:lastarg().."\n"
end
Handlers[RPL.MOTD] = function(irc, msg)
	irc.motd = (irc.motd or "")..msg:lastarg().."\n"
end
Handlers[RPL.ENDOFMOTD] = function(irc, msg)
	irc.motd = (irc.motd or "")..msg:lastarg().."\n"
	irc:emit("motd", irc.motd)
end
Handlers[ERR.NOMOTD] = Handlers[RPL.ENDOFMOTD]

return Handlers