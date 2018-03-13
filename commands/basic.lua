return {
	ping = {
		forusers = true,
		description = "Pong!",
		callback = function(msg,args,line,config)
			msg:reply({
				embed = {
					title = ":ping_pong: Pong!",
					color = 0x0275d8,
				}
			})
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

			for sts, dat in next, status do
				local plyList
				if dat.plylist == nil or #dat.plylist == 0 then
					plyList = "."
				elseif #dat.plylist > 32 then
					plyList = ": ```\n" .. table.concat({unpack(dat.plylist, 1, 64)}, ", ") .. " + " .. (#dat.plylist - 32) .. "more\n```"
				else
					plyList = ": ```\n" .. table.concat(dat.plylist, ", ") .. "\n```"
				end

				embed.fields[#embed.fields + 1] = {
					name = dat.title,
					value = ([[:map: **Map**: `%s`
:busts_in_silhouette: **%s players**%s]]):format(dat.map, tostring(dat.players), plyList)
				}
			end

			msg:reply({
				embed = embed
			})
			return true
		end
	}
}
