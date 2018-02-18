return {
    disable = {
        description = "Disables the relay. (will stop logging the chat in #metastruct IRC channel, etc.)",
        callback = function(msg,args,line,obj)
            obj.irc:say("#test", "brb in idk minutes (going into the maintenance)")
            _G.config.enabled = false
        end
    },
    enable = {
        description = "Enables the relay. (will continue logging the chat in #metastruct IRC channel, etc.)",
        callback = function(msg,args,line,obj)
            _G.config.enabled = true
            obj.irc:say("#test", "back from maintenance")
        end
    }
}