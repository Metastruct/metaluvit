--[[
lit-meta
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

local wrap = coroutine.wrap
local sub = string.sub
local len = string.len

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

local function starts(String,Start)
	return sub(String,1,len(Start)) == Start
end

local function ends(String,End)
	return End == "" or sub(String,-len(End)) == End
end

local json = require("json").use_lpeg()
_G.status = {}

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

local function EE(...)
	return {
		embed = {
			title = "Error:",
			description = "```" .. sub(tostring(...), 0, 2000) .. "```",
			color = 0xff0000
		}
	}
end
local http = require("http")
require("helpers/image")


local Webhook = string.Split(config.webhook, "/")

local function doWebhook(tbl)
	return client and client._api:executeWebhook(Webhook[1], Webhook[2], tbl)
end


client:on("ready", function()
	guild = client:getGuild(serverid)
	channel = guild:getChannel(channelid)
	print("Logged in as " .. client.user.username)
end)

client:on("messageCreate", function(message)
	if message.channel == channel and message.author ~= client.user and config.enabled == true and message.author.discriminator ~= "0000" then
		--[[if message.content == ".status" then
			message:reply("did you mean `!status`?")
			return
		end]]

		if starts(message.content, ".") and message.content ~= ".status" and message.content:len() > 1 then
			c:say("#metastruct", "Command call requested by " .. message.author.username .. "#" .. message.author.discriminator .. ":")
			c:say("#metastruct", message.content)
		else
			local hasAttachments = message.attachment
			local hasEmbeds = message.embeds
			local attachments = "\n"
			local embeds = attachments
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
			if hasEmbeds then -- todo make sparate function to handle all objects
				local n = #hasEmbeds
				for i = 1, n do
					embeds =	--(hasEmbeds[i].url and hasEmbeds[i].url or "" .. "\n") ..
								(hasEmbeds[i].title and hasEmbeds[i].title .. " " or "") ..
								(hasEmbeds[i].description and hasEmbeds[i].description or "" .. "\n")
				end
			end
			local msg = message.content
			msg = msg:gsub("<@!?(%d-)>", function(id) --  nickname from id
				return "@" .. getDiscordNick(id)
			end)
			msg = msg:gsub("<a?(:.-:)%d->", function(id) -- format emotes
				return id
			end)
			c:say("#metastruct", "[" .. message.author.username .. "] " .. msg .. embeds ..  attachments)
		end
	end
end)

local function cleanContent(str)
	return str:gsub("(@+)everyone", "everyone"):gsub("(@+)here", "here")
end

local function handleIRC(from, to, msg)
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
	safemessage = cleanContent(safemessage)
	safemessage = safemessage:gsub("`", "\\`")
	--safemessage = safemessage:gsub("_", "\\_") -- breaks urls
	safemessage = safemessage:gsub("*", "\\*")

	pcall(function()
		channel:send(id .. safemessage)
	end)
end

local WSEvents = {
	status = function(sts,data)
		_G.status[sts] = data.status
	end,
	msg = function(sts,data)
		if Webhook then
			-- local file = image.getByURL(data.msg.avatar or "http://i.imgur.com/ovW4MBM.png")
			wrap(function()
				local msg = data.msg.txt
				if not msg then return end

				if msg:match("@%w+") then
					for mention in msg:gmatch("@(%w+)") do
						local uid = findDiscordUserID(mention)
						if uid then
							msg = msg:gsub("@" .. mention, "<@" .. uid .. ">")
						end
					end
				end

				msg = cleanContent(msg)

				local username = #data.msg.nickname > 26 and (data.msg.nickname:sub(1, 26) .. "...") or data.msg.nickname

				doWebhook({
					username = sts .. " " .. username,
					avatar_url = data.msg.avatar or "http://i.imgur.com/ovW4MBM.png",
					content = msg
				})
			end)()
		end
	end,
	disconnect = function(sts,data)
		 wrap(function()
						channel:send({
								embed = {
										author = {
												icon_url = data.disconnect.avatar or "http://i.imgur.com/ovW4MBM.png",
												name = data.disconnect.nickname .. " has left the server.",
												url = "http://steamcommunity.com/profiles/" .. data.disconnect.steamid
										},
										fields = data.disconnect.reason ~= "" and {
												[1] = {
														name = "Reason:",
														value = data.disconnect.reason
												}
										},
										footer = {
												text = "Server " .. sts
										},
										color = 0xB54343
								}
						})
				end)()
	end,
	spawn = function(sts,data)
		 wrap(function()
						channel:send({
								embed = {
										author = {
												icon_url = data.spawn.avatar or "http://i.imgur.com/ovW4MBM.png",
												name = data.spawn.nickname .. " has spawned.",
												url = "http://steamcommunity.com/profiles/" .. data.spawn.steamid
										},
										footer = {
												text = "Server " .. sts
										},
										color = 0x4BB543
								}
						})
				end)()
	end,
	shutdown = function(sts,data)
		_G.status[sts] = { players = {}, title = "Meta Construct " .. sts, map = "gm_unknown" }
				wrap(function()
						channel:send({
								embed = {
										title = "Server " .. sts .. " shutting down...",
										description = "Resetting status...",
										footer = {
												text = "Server " .. sts
										},
										color = 0x0275d8
								}
						})
				end)()
	end,
	notify = function(sts,data)
		if not data.notify.text then return end
				wrap(function()
						channel:send({
								embed = {
										title = data.notify.title or "",
										description = data.notify.text,
										footer = {
												text = "Server " .. sts
										},
										color = data.notify.color or 0xffff00
								}
						})
				end)()
	end,
	webhook = function(sts,data)
		if type(data.webhook) ~= "table" or next(data.webhook) == nil then return end
				local wh = data.webhook
				if wh.content or wh.embeds then
				wh.content = wh.content and cleanContent(wh.content)
						wrap(function()
								local ok, why = doWebhook(wh)
								if not ok then channel:send( EE(why) ) end
						end)()
				else
						wrap(function()
								channel:send( EE("received invalid embed?") )
						end)()
				end
	end
}

local function handleWS(data,write)
	if data == nil then return end

	if type(data) == "string" then
		data = json.parse(data) or {}
	end
	local sts = "#" .. (data.server or "-1")
	for name,_ in next,data do
		if WSEvents[name] then
			WSEvents[name](sts,data)
		end
	end
end

local timer = require("timer")
timer.setInterval(10000, function()
	if client and status then
		local str = ""
		for k, dat in next, status do
			str = str .. (dat.players and #dat.players or "0") .. " players on " .. k .. " | "
		end
		str = str .. "!status"

		wrap(function()
			client:setGame(str)
		end)()
	end
end)

local serverips = {
	"195.154.166.219",
	"94.23.170.2"
}

require("weblit-websocket")
local wlit = require("weblit-app")
	.bind({host = "0.0.0.0", port = 20122})

	.use(require("weblit-logger"))
	.use(require("weblit-auto-headers"))

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
			local success, err = pcall(handleWS, message.payload, write)
			if not success then print(err) end
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

	if (from ~= "Discord" and to == "#metastruct" and config.enabled == true and not starts(from,"meta")) then
		wrap(function() handleIRC(from, to, msg) end)()
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
			param and " " .. param or ""
		))
	end)
	channel:on("-mode", function(mode, setby, param)
		if setby == nil then return end
		print(string.format("[%s] %s sets mode: %s%s",
			channel,
			setby,
			"-" .. mode.flag,
			param and " " .. param or ""
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
