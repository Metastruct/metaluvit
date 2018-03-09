
--[[lit-meta
name = "metaluvit"
version = "0.0.1"
dependencies = {}
description = "Metastruct Luvit Based Daemon"
tags = { "metastruct", "chat", "luvit" }
license = "MIT"
author = { name = "metastruct", email = "metastruct@metastruct.uk.to" }
homepage = "https://metastruct.net"
]]

_G.require = require
setfenv(1, _G)

require("./helpers/util.lua")

_G.config = require("config")
local serverid = config.guildid
local channelid = config.channelid

if not serverid or not channelid or not config.groups.devs or not config.groups.admins then
		p "Please setup env. variables: DISCORDGUILD, DISCORDCHANNEL, DISCORD_GROUP_DEVELOPERS, DISCORD_GROUP_ADMINS."
		p "One of them is not set up."
		p "Crashing..."
		process.exit(1)
end

local discordia = require("discordia")
local client = discordia.Client {
	cacheAllMembers = true,
}
local IRC = require ("irc")

function string.starts(String,Start)
	return string.sub(String,1,string.len(Start)) == Start
end

function string.ends(String,End)
	return End == "" or string.sub(String,-string.len(End)) == End
end

local json = require('json').use_lpeg()
_G.status = {
	["#1"] = {},
	["#2"] = {}
}

local c = IRC:new ("irc.3kv.in", "Discord", {auto_connect = true, auto_join = {"#metastruct"}})
local guild
local channel

_G.config.enabled = true
_G.config.irc = c
_G.config.client = client
_G.commands = {}

require("./handlers/cmd.lua")(config)

local function getDiscordNick(id)
	local usr = guild.members:find(function(obj)
		return obj.id == id
		end)
	return usr and usr.name or "UserNotFound"
end

local function findDiscordUserID(name)
	local usr = guild.members:find(function(obj)
		return obj.name == name
		end)
	return usr and usr.id
end

client:on("ready", function()
	guild = client:getGuild(serverid)
	channel = guild:getChannel(channelid)
	print("Logged in as " .. client.user.username)
end)

client:on("messageCreate", function(message)
	if message.channel == channel and message.author ~= client.user and config.enabled == true then
		--[[if message.content == ".status" then
			message:reply("did you mean `!status`?")
			return
		end]]

		if message.content:starts(".") and message.content ~= ".status" and message.content:len() > 1 then
			c:say("#metastruct", "Command call requested by " .. message.author.username .. "#" .. message.author.discriminator .. ":")
			c:say("#metastruct", message.content)
		else
			local hasAttachments = message.attachment
			local attachments = "\n"
			if hasAttachments then
				if message.attachments then
					local tbl = message.attachments
					for i = 1, #tbl do
						attachments = attachments .. tbl[i].url .. (i > 1 and  " , " or "")
					end
				else
					attachments = hasAttachments.url
				end
			end
			local msg = message.content
			msg = msg:gsub("<@!?(%d-)>", function(id) --  nickname from id
				return "@" .. getDiscordNick(id)
			end)
			msg = msg:gsub("<a?(:.-:)%d->", function(id) -- format emotes
				return id
			end)
			c:say("#metastruct", "[" .. message.author.username .. "] " .. msg .. attachments)
		end
	end
end)

local function HandleIRC(from, to, msg)
	local id = "**<" .. from .. ">** "
	if msg:match("@%w+") then
		for mention in msg:gmatch("@(%w+)") do
			local uid = findDiscordUserID(mention)
			if uid then
				msg = msg:gsub("@" .. mention, "<@" .. uid .. ">")
			end
		end
	end
	local safemessage = tostring(IRC.Formatting.strip(msg))
	if from:find"meta[0-3]" and safemessage:find"^#" then
		id = ""
	end
	-- Discord Markdown escape
	safemessage = safemessage:gsub("`", "\\`")
	--safemessage = safemessage:gsub("_", "\\_") -- breaks urls
	safemessage = safemessage:gsub("*", "\\*")

	channel:send(id .. safemessage)
end

local function handleWS(data,write)
	if data == nil then return end 
	
	if type(data) == "string" then
		data = json.parse(data) or {}
	end
	local sts = data.server or "??"
	if data.status then
		local tbl = data.status
		_G.status[sts] = tbl
		if client then
			client:setGame((status["#1"].players or "??").." players on #1 | "..(status["#2"].players or "??").." players on #2 | !status")
		end
	end

	if data.msg then
		local txt = sts.." "..data.msg.nickname..": "..data.msg.txt
		coroutine.wrap(function() channel:send(txt) end)()
	end

	if data.disconnect then
		coroutine.wrap(function()
			channel:send({
				embed = {
					author = {
						icon_url = data.disconnect.avatar or "https://cdn1.iconfinder.com/data/icons/user-experience-dotted/512/avatar_client_person_profile_question_unknown_user-512.png",
						name = data.disconnect.nickname or "WTF?"
					},
					title = data.disconnect.nickname.." has left the server.",
					description = "Reason: "..data.disconnect.reason,
					footer = {
						text = data.disconnect.steamid.." | Server "..sts
					},
					color = 0x0275d8
				}
			})
		end)()
	end

	if data.connect then
		coroutine.wrap(function()
			channel:send({
				embed = {
					author = {
						icon_url = data.connect.avatar or "https://cdn1.iconfinder.com/data/icons/user-experience-dotted/512/avatar_client_person_profile_question_unknown_user-512.png",
						name = data.connect.nickname or "WTF?"
					},
					title = data.connect.nickname.." is connecting to the server.",
					footer = {
						text = data.connect.steamid.." | Server "..sts
					},
					color = 0x4BB543
				}
			})
		end)()
	end

	if data.shutdown then
		handleWS({status={players="??",title="Meta Construct "..sts,plylist={},map="gm_unknown"},server=sts})
		coroutine.wrap(function()
			channel:send({
				embed = {
					title = "Server "..sts.." shutting down...",
					description = "Resetting status...",
					footer = {
						text = "Server "..sts
					},
					color = 0x0275d8
				}
			})
		end)()
	end
end

local serverips = {
	"195.154.166.219",
	"94.23.170.2"
}

require('weblit-websocket')
local wlit = require('weblit-app')
	.bind({host = "0.0.0.0", port = 20122})

	.use(require('weblit-logger'))
  	.use(require('weblit-auto-headers'))

	.websocket({
		path = "/v2/socket"
	}, 
	function (req, read, write)
		print("New client")
		print("checking ip...")
		local here = false
		for _, serverip in pairs(serverips) do
			local ip = req.socket:getsockname().ip
			if ip == serverip or ip == "::1" or ip == "::" or ip == "127.0.0.1" then
				here = true
			end
		end

		if not here then
			write()
			print("ok bye")
		end

		for message in read do
			message.mask = nil
			handleWS(message.payload,write)
			write(message)
		end
		write()
		print("Client left")
	end)
	.route({ path = "/:name"}, function (req, res)
			res.body = req.method .. " - " .. req.params.name .. "\n"
			res.code = 200
			res.headers["Content-Type"] = "text/plain"
	end)
	.start()

c:on ("message", function (from, to, msg)
	print ("[" .. to .. "] <" .. from .. "> " .. IRC.Formatting.convert(msg))

	if (from ~= "Discord" and to == "#metastruct" and config.enabled == true and not string.starts(from,"meta")) then
		coroutine.wrap(function() HandleIRC(from, to, msg) end)()
	end

end)
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
		print(string.format("[%s] %s has left the channel", channel, who) .. (reason and " (" .. reason .. ")" or ""))
	end)
	channel:on("kick", function(who, by, reason)
		print(string.format("[%s] %s has been kicked from the channel by %s", channel, who, by) .. (reason and " (" .. reason .. ")" or ""))
	end)
	channel:on("quit", function(who, reason)
		print(string.format("[%s] %s has quit", channel, who) .. (reason and " (" .. reason .. ")" or ""))
	end)
	channel:on("kill", function(who)
		print(string.format("[%s] %s has been forcibly terminated by the server", channel, who))
	end)
	channel:on("+mode", function(mode, setby, param)
		if setby == nil then return end
		print(string.format("[%s] %s sets mode: %s%s",
			channel,
			setby,
			"+" .. mode.flag,
			(param and " " .. param or "")
		))
	end)
	channel:on("-mode", function(mode, setby, param)
		if setby == nil then return end
		print(string.format("[%s] %s sets mode: %s%s",
			channel,
			setby,
			"-" .. mode.flag,
			(param and " " .. param or "")
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
	print("Users in channel " .. tostring(channel) .. ":")
	for nick,user in pairs(channel.users) do
		print(" " .. tostring(user))
	end
end)

c:on ("pm", function (from, msg)
	print ("<" .. from .. "> " .. IRC.Formatting.convert(msg))
end)

c:on ("disconnect", function (reason)
	print (string.format("Disconnected: %s", reason))
end)

c:on ("unhandled", function(msg)
	p("Unhandled message", msg)
end)

local os = require"os"
if os.getenv"DISCORDKEY" then
	client:run("Bot " .. os.getenv("DISCORDKEY"))
else
	print"NO DISCORD KEY"
end

print"Initialized"
