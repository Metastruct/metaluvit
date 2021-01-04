local config = require'config'
local discord = require("modules/discord")
local os = require"os"

if not config.guildID or not config.channelID or not config.groups.devs or not config.groups.admins then
	log:error("Please setup env. variables: DISCORDGUILD, DISCORDCHANNEL, DISCORD_GROUP_DEVELOPERS, DISCORD_GROUP_ADMINS.")
	log:error("One of them is not set up.")
	log:error("Crashing...")
	return process.exit(1)
end

require("modules/discord_commands")

if os.getenv("DISCORDKEY") then
	discord:run("Bot " .. os.getenv("DISCORDKEY"))
else
	log:error("No Discord Token!")
	return process.exit(1)
end

