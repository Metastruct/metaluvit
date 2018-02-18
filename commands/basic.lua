return {
    ping = {
        description = "Simple command.",
        callback = function(msg,args,line,config)
            msg:reply("Pong")
        end
    }
}