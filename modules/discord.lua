local discordia = require("discordia")

local client = discordia.Client({
	cacheAllMembers = true,
})

client:on("ready", function()
	config.guild = client:getGuild(config.guildID)
	if not config.guild then
		print("Error, guild not found. Did you add the bot to your server..?")
		process:exit(1)
	end

	config.channel = config.guild:getChannel(config.channelID)

    print("Logged in as " .. client.user.username)
end)

return client