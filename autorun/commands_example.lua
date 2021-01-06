
local cmds = require'modules/discord_commands'

cmds:add("ping",
	function(msg, args, line)
		msg:reply({
			embed = {
				title = ":ping_pong: Pong!",
				color = 0x0275d8,
			}
		})
		return true
	end,{
			description = "Pong!",
	})
