return {
    ping = {
        description = "Simple command.",
        callback = function(msg,args,line)
            msg:reply("Pong")
        end
    },
}