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
				if not dat.players then dat.players = {} end -- ???

				local plyList
				if #dat.players == 0 then
					plyList = "."
				elseif #dat.players > 48 then
					plyList = ": ```\n" .. table.concat({unpack(dat.players, 1, 48)}, ", ") .. " + " .. (#dat.players - 48) .. "more\n```"
				else
					plyList = ": ```\n" .. table.concat(dat.players, ", ") .. "\n```"
				end

				embed.fields[#embed.fields + 1] = {
					name = dat.title,
					value = ([[:map: **Map**: `%s`
:busts_in_silhouette: **%s players**%s]]):format(dat.map, tostring(#dat.players), plyList)
				}
			end

			msg:reply({
				embed = embed
			})
			return true
		end
	}
}
