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



			for sts, data in pairs(status) do
				local plyList
				if data.plylist == nil or #data.plylist == 0 then
					plyList = "none."
				else
					plyList = "```\n" .. table.concat(data.plylist, ", ") .. "\n```"
				end

                local val = ([[
:map: **Map**: `%s`
:busts_in_silhouette: **%s players**: %s
                ]]):format(data.map, tostring(data.players), plyList)

                embed.fields[#embed.fields + 1] = {
                    title = data.title,
                    value = val,
                }
            end

            msg:reply({embed=embed})
            return true
        end
    }
}