
return {
	ping = {
		description = "Pong!",
		callback = function(msg, args, line)
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
		description = "Status of game server.",
		callback = function(msg, args, line)
			for i, server in next, config.gameservers do
				local data = instances.webapp.serverStatus["#" .. i]
				if data then
					if not data.players then data.players = {} end -- ???

					local embed = {
						color = 0x0275d8,
						author = {}
					}

					local plyList
					if #data.players == 0 then
						plyList = "."
					elseif #data.players > 48 then
						plyList = ": ```\n" .. table.concat({ unpack(data.players, 1, 48) }, ", ") .. " + " .. (#data.players - 48) .. "more\n```"
					else
						plyList = ": ```\n" .. table.concat(data.players, ", ") .. "\n```"
					end

					embed.author.name = data.title or "???"
					embed.author.url = server.joinURL
					embed.author.icon_url = server.icon or "http://metastruct.net/static/DefaultServerIcon.png"

					embed.description = ([[:map: **Map**: `%s`
	:busts_in_silhouette: **%s players**%s]]):format(data.map, tostring(#data.players), plyList)

					msg:reply({
						embed = embed
					})
				else
					print("#" .. id .. " has no data??")
				end
			end

			return true
		end
	}
}
