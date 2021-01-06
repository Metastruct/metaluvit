local discordia = require("discordia")
local config = require("config")
local slash = require("discordia-slash")
local log = require("modules/logsys")
local hook = require("modules/hook")

local _M={}

local client = discordia.Client({
	cacheAllMembers = true,
})
client=client:useSlashCommands()
_M.client=client

client:on("slashCommandsReady", function()
	log:debug("slashCommandsReady")
	print"slashCommandsReady"
	hook.run("slashCommandsReady",slash,client)
end)



client:on("messageCreate", function(msg)
    print(msg.author.name,
	msg.channel and msg.channel.name,
	msg.member and msg.member:hasRole(config.groups.devs) and "(DEV)" or "",
	msg.content)
	_G.asd=msg
end)

client:on("ready", function()
	_M.guild = client:getGuild(config.guildID)
	if not _M.guild then
		log:error("Error, guild not found. Did you add the bot to your server..?")
		process:exit(1)
	end

	_M.channel = _M.guild:getChannel(config.channelID)

    log:info("Discord","Logged in as " .. client.user.username)
end)


local webhook = string.Split(config.webhook, "/")

function _M.execWebhook(tbl)
	return client and client._api:executeWebhook(webhook[1], webhook[2], tbl)
end

return _M
