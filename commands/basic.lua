return {
    ping = {
        description = "Simple command.",
        callback = function(msg,args,line,config)
            msg:reply("Pong")
            return true
        end
    },
    status = {
        forusers = true,
        description = "Status of game server.",
        callback = function(msg,args,line,config)
            local embed = {
                title = "Status",
                fields = {},
                color = 0x0275d8
            }

            for sv,sts in pairs(status) do
                embed.fields[#embed.fields+1] = {
                    name = "Server "..sv,
                    value = ([[
                        **Hostname:** %s
**Players:** %s
**Map:** %s

**Players:** %s
                    ]]):format(sts.title,tostring(sts.players),sts.map,table.concat(sts.plylist or {},"`, `") == "" and "none." or "`"..table.concat(sts.plylist or {},"`, `").."`")
                }
            end

            msg:reply({embed=embed})
            return true
        end
    }
}