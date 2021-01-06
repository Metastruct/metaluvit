local os = require("os")

local config={}
config.channelID = os.getenv("DISCORDCHANNEL")
config.guildID = os.getenv("DISCORDGUILD")
config.webhook = os.getenv("DISCORDWEBHOOK")
config.groups = {
	devs = os.getenv("DISCORD_GROUP_DEVELOPERS"),
	admins = os.getenv("DISCORD_GROUP_ADMINS")
}

config.prefix = "[!/%.]"

config.gameservers = {
	[1] = {
		joinURL = "https://metastruct.net/join/eu1",
		icon = "http://metastruct.net/static/DefaultServerIcon.png", -- todo make icons for both
		ip = "195.154.166.219",
	},
	[2] = {
		joinURL = "https://metastruct.net/join/eu2",
		icon = "http://metastruct.net/static/DefaultServerIcon.png",
		ip = "94.23.200.74"
	},
	[3] = {
		joinURL = "https://metastruct.net/join/us1",
		icon = "http://metastruct.net/static/DefaultServerIcon.png",
		ip = "66.42.103.116"
	}
}

return config
