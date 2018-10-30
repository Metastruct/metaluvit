return {
    disable = {
        admin = true,
        description = "Disables the relay. (will stop logging the chat in #metastruct IRC channel, etc.)",
        callback = function(msg, args, line)
            config.enabled = false

            instances.irc:say("#metastruct", "brb in idk minutes (going into the maintenance)")
            msg:reply(":white_check_mark:")
        end
    },
    enable = {
        admin = true,
        description = "Enables the relay. (will continue logging the chat in #metastruct IRC channel, etc.)",
        callback = function(msg, args, line)
            config.enabled = true

            instances.irc:say("#metastruct", "back from maintenance")
            msg:reply(":white_check_mark:")
        end
    }
}
