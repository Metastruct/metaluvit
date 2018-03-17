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
				author = {},
				fields = {}
			}

			local servers = {  -- move to config file?
				[1] = {
					url = "steam://connect/g1.metastruct.net",
					icon = "http://metastruct.net/static/DefaultServerIcon.png" -- todo make icons for both
				},
				[2] = {
					url = "steam://connect/g2.metastruct.net:27018",
					icon = "http://metastruct.net/static/DefaultServerIcon.png"
				}
			}

			for sts, dat in next, status do
				if not dat.players then dat.players = {} end -- ???
				local server = servers[dat.server] or {}

				local plyList
				if #dat.players == 0 then
					plyList = "."
				elseif #dat.players > 48 then
					plyList = ": ```\n" .. table.concat({unpack(dat.players, 1, 48)}, ", ") .. " + " .. (#dat.players - 48) .. "more\n```"
				else
					plyList = ": ```\n" .. table.concat(dat.players, ", ") .. "\n```"
				end

				author.name = dat.title or "???"
				author.url = server.url or ""
				author.icon_url = server.icon or "http://metastruct.net/static/DefaultServerIcon.png"

				embed.fields[#embed.fields + 1] = {
					name = " ",
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
