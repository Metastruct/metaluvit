--[[
lit-meta
name = "metaluvit"
version = "0.0.1"
dependencies = {}
description = "Metastruct Luvit Based Daemon"
tags = { "metastruct", "chat", "luvit" }
license = "MIT"
author = { name = "metastruct", email = "metastruct@metastruct.uk.to" }
homepage = "https://metastruct.net/"
]]
--

_G.require = require
setfenv(1, _G)

local _print = print
_G.print = function(...)
    _print(string.format('[%s] ', os.date('%Y-%m-%d %H:%M:%S')), ...)
end

require("./helpers/util.lua")

_G.config = require("config")

if not config.guildID or not config.channelID or not config.groups.devs or not config.groups.admins then
	print("Please setup env. variables: DISCORDGUILD, DISCORDCHANNEL, DISCORD_GROUP_DEVELOPERS, DISCORD_GROUP_ADMINS.")
	print("One of them is not set up.")
	print("Crashing...")
	process.exit(1)
end

_G.config.enabled = true

_G.instances = {}
_G.instances.irc = require("./modules/irc.lua")
_G.instances.discord = require("./modules/discord.lua")
_G.instances.webapp = require("./modules/webapp.lua")

require("./modules/discord_commands.lua")
require("./modules/discord_irc.lua")

-- require("./helpers/image.lua") -- now unused??

local os = require"os"
if os.getenv("DISCORDKEY") then
	instances.discord:run("Bot " .. os.getenv("DISCORDKEY"))
else
	print("No Discord Token!")
end

instances.webapp.start()

print("Initialized")

require("./modules/repl.lua")
