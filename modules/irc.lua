local irc = require("irc")

local c = irc:new("irc.3kv.in", "Discord", { auto_connect = true, auto_join = {"#metastruct"} })

c:on("message", function(from, to, msg)
	loggedprint("[" .. to .. "] <" .. from .. "> " .. irc.Formatting.convert(msg))
end)

c:on("connecting", function(nick, server, username, realname)
	loggedprint(string.format("Connecting to %s as %s...", server, nick))
end)
c:on("connect", function(welcomemsg, server, nick)
	loggedprint(string.format("Connected to %s as %s", server, nick))
end)
c:on("connecterror", function(err)
	loggedprint(string.format("Could not connect: %s", err))
end)
c:on("disconnect", function(reason)
	loggedprint(string.format("Disconnected: %s", reason))
end)
c:on("notice", function(from, to, msg)
	from = from or c.server
	loggedprint(string.format("-%s:%s- %s", from, to, msg))
end)
c:on("error", function(...)
	loggedprint(...)
	process.exit(1)
end)
-- c:on("data", function(...) end)

c:on("ijoin", function(channel, who)
	loggedprint(string.format("Joined channel: %s", channel))

	channel:on("join", function(who)
		loggedprint(string.format("[%s] %s has joined the channel", channel, who))
	end)
	channel:on("part", function(who, reason)
		loggedprint(string.format("[%s] %s has left the channel", channel, who) .. (reason and " (" .. reason .. ")" or ""))
	end)
	channel:on("kick", function(who, by, reason)
		loggedprint(string.format("[%s] %s has been kicked from the channel by %s", channel, who, by) .. (reason and " (" .. reason .. ")" or ""))
	end)
	channel:on("quit", function(who, reason)
		loggedprint(string.format("[%s] %s has quit", channel, who) .. (reason and " (" .. reason .. ")" or ""))
	end)
	channel:on("kill", function(who)
		loggedprint(string.format("[%s] %s has been forcibly terminated by the server", channel, who))
	end)
	channel:on("+mode", function(mode, setby, param)
		if setby == nil then return end
		loggedprint(string.format("[%s] %s sets mode: %s%s",
			channel,
			setby,
			"+" .. mode.flag,
			param and " " .. param or ""
		))
	end)
	channel:on("-mode", function(mode, setby, param)
		if setby == nil then return end
		loggedprint(string.format("[%s] %s sets mode: %s%s",
			channel,
			setby,
			"-" .. mode.flag,
			param and " " .. param or ""
		))
	end)
end)

c:on("ipart", function(channel, reason)
	loggedprint(string.format("Left channel: %s", channel.name))
end)
c:on("ikick", function(channel, kickedby, reason)
	loggedprint(string.format("Kicked from channel: %s by %s (%s)", channel.name, kickedby, reason))
end)

c:on("names", function(channel)
	loggedprint("Users in channel " .. tostring(channel) .. ":")
	for nick, user in pairs(channel.users) do
		loggedprint(" " .. tostring(user))
	end
end)
c:on("pm", function(from, msg)
	loggedprint("<" .. from .. "> " .. irc.Formatting.convert(msg))
end)

c:on("unhandled", function(msg)
	p("Unhandled message", msg)
end)

return c