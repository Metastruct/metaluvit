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
			local servers = {  -- move to config file?
				[1] = {
					url = "https://metastruct.net/join/eu1",
					icon = "http://metastruct.net/static/DefaultServerIcon.png" -- todo make icons for both
				},
				[2] = {
					url = "https://metastruct.net/join/eu2",
					icon = "http://metastruct.net/static/DefaultServerIcon.png"
				}
			}

			for i = 1, #servers do
				local embed = {
					color = 0x0275d8,
					author = {}
				}
				local dat = status["#" .. i]
				if not dat.players then dat.players = {} end -- ???
				local server = servers[i] or {}

				local plyList
				if #dat.players == 0 then
					plyList = "."
				elseif #dat.players > 48 then
					plyList = ": ```\n" .. table.concat({unpack(dat.players, 1, 48)}, ", ") .. " + " .. (#dat.players - 48) .. "more\n```"
				else
					plyList = ": ```\n" .. table.concat(dat.players, ", ") .. "\n```"
				end

				embed.author.name = dat.title or "???"
				embed.author.url = server.url
				embed.author.icon_url = server.icon or "http://metastruct.net/static/DefaultServerIcon.png"

				embed.description = ([[map: **Map**: `%s`
:busts_in_silhouette: **%s players**%s]]):format(dat.map, tostring(#dat.players), plyList)

				msg:reply({
					embed = embed
				})
			end
			return true
		end
	}
}
