local IRC = require ('.')
local util = require "./lib/util"
local string = require "string"

local server = "irc.esper.net"
local ssl = false
local nick = "lubot3"

local c = IRC:new (server, nick, {ssl=ssl, auto_join={"#squeektest", "#jkl"}})
c:on ("connecting", function(nick, server, username, real_name)
	print(string.format("Connecting to %s as %s...", server, nick))
end)
c:on ("connect", function (welcomemsg, server, nick)
	print(string.format("Connected to %s as %s", server, nick))
end)
c:on ("connecterror", function (err)
	print(string.format("Could not connect: %s", err))
end)
c:on ("error", function (...)
	p (...)
	process.exit (1)
end)
c:on ("notice", function (from, to, msg)
	from = from or c.server
	print(string.format("-%s:%s- %s", from, to, msg))
end)
c:on ("data", function (...)
	--p (...)
end)
c:on ("ijoin", function (channel, whojoined)
	print(string.format("Joined channel: %s", channel))

	channel:on("join", function(whojoined)
		print(string.format("[%s] %s has joined the channel", channel, whojoined))
	end)
	channel:on("part", function(who, reason)
		print(string.format("[%s] %s has left the channel", channel, who)..(reason and " ("..reason..")" or ""))
	end)
	channel:on("kick", function(who, by, reason)
		print(string.format("[%s] %s has been kicked from the channel by %s", channel, who, by)..(reason and " ("..reason..")" or ""))
	end)
	channel:on("quit", function(who, reason)
		print(string.format("[%s] %s has quit", channel, who)..(reason and " ("..reason..")" or ""))
	end)
	channel:on("kill", function(who)
		print(string.format("[%s] %s has been forcibly terminated by the server", channel, who))
	end)
	channel:on("+mode", function(mode, setby, param)
		if setby == nil then return end
		print(string.format("[%s] %s sets mode: %s%s",
			channel,
			setby,
			"+"..mode.flag,
			(param and " "..param or "")
		))
	end)
	channel:on("-mode", function(mode, setby, param)
		if setby == nil then return end
		print(string.format("[%s] %s sets mode: %s%s",
			channel,
			setby,
			"-"..mode.flag,
			(param and " "..param or "")
		))
	end)
end)
c:on ("ipart", function (channel, reason)
	print(string.format("Left channel: %s", channel.name))
end)
c:on ("ikick", function (channel, kickedby, reason)
	print(string.format("Kicked from channel: %s by %s (%s)", channel.name, kickedby, reason))
end)
c:on ("names", function(channel)
	print("Users in channel "..tostring(channel)..":")
	for nick,user in pairs(channel.users) do
		print(" "..tostring(user))
	end
end)
c:on ("pm", function (from, msg)
	print ("<"..from.."> "..IRC.Formatting.convert(msg))
end)
c:on ("message", function (from, to, msg)
	print ("["..to.."] <"..from.."> "..IRC.Formatting.convert(msg))
end)
c:on ("disconnect", function (reason)
	print (string.format("Disconnected: %s", reason))
end)
c:on ("unhandled", function(msg)
	p("Unhandled message", msg)
end)

function irc_cmd (input)
	local lines = util.string.split(input, "\r?\n")

	for _,line in ipairs(lines) do
		if line ~= "" then
			local args = util.string.split(line, " ")
			if args[1] == "/quit" then
				c:disconnect ()
			elseif args[1] == "/connect" then
				c:connect ()
			elseif args[1] == "/join" then
				c:join (channel)
			elseif args[1] == "/part" then
				if #args > 1 then
					c:part (args[2])
				end
			elseif args[1] == "/query" then
				local target = args[2]
				local text = util.string.join(util.table.slice(args, 3), " ")
				c:say (target, text)
			elseif args[1] == "/names" then
				if #args > 1 then
					c:names (args[2])
				end
			elseif line:sub (1, 1) == "!" then
				c:write (line:sub (2).."\r\n")
			elseif args[1]:sub(1,1) ~= "/" then
				c:say ("#", line)

				for _,channel in pairs(c.current_channels) do
					c:emit("message", c.nick, channel.name, line)
				end
			end
		end
	end
end

c:connect ()
process.stdin:on ("data", function (...)
	irc_cmd (...)
end)
