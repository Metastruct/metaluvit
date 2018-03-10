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
                title = ":globe_with_meridians: Status",
                color = 0x0275d8,
                fields = {}
            }

            local wat = ""

            for sts,dat in next,status do
                local plyList
				if dat.plylist == nil or #dat.plylist == 0 then
					plyList = "none."
				else
					plyList = "```\n" .. table.concat(dat.plylist, ", ") .. "\n```"
                end
                
                wat = wat..([[
Server %s
:map: **Map**: `%s`
:busts_in_silhouette: **%s players**: %s
                    ]]):format(sts, dat.map, tostring(dat.players), plyList)
            end

            embed.description = wat

            msg:reply({embed=embed})
            return true
        end
    }
}