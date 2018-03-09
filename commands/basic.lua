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
                fields = {},
                color = 0x0275d8
            }

			for _, data in pairs(status) do
				local plyList = "```\n%s\n```"
				if data.plylist == nil or #data.plylist == 0 then
					plyList = plyList:format("none.")
				else
					plyList = plyList:format(table.concat(data.plylist, ", "))
				end

                embed.fields[#embed.fields + 1] = {
                    name = data.title,
                    value = ([[
:map: **Map**: `%s`
:busts_in_silhouette: **Players**: %s (%s)
                    ]]):format(data.map, plyList, tostring(data.players))
                }
            end

            msg:reply({embed=embed})
            return true
        end
    }
}