local os = require 'os'

return {
    channelid = os.getenv("DISCORDCHANNEL"),
    guildid = os.getenv("DISCORDGUILD"),
    groups = {
        devs = os.getenv("DISCORD_GROUP_DEVELOPERS"),
        admins = os.getenv("DISCORD_GROUP_ADMINS")
    },
    prefix = "[!/%.]"
}