
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
	}
}
