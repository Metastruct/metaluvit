local fs = require"fs"
local config = require'config'
local discord = require'modules/discord'

local _M = {
	list = {}
}

function _M:add(name, callback, attrs)
	attrs = attrs or {}
	attrs.callback = callback
	attrs.name = name
	self.list[name] = attrs

	return attrs
end

function _M:remove(command)
	if not self.list[command] then return false, "command does not exist" end
	self.list[command] = nil

	return true
end

discord.client:on("messageCreate", function(msg)
	local content = msg.content
	local prefix = content:match("^" .. config.prefix)
	if not prefix then return end
	if msg.author.bot then return end
	local cmdStart, cmdEnd = content:find" "
	cmdStart = cmdStart or #content
	cmdEnd = cmdEnd or #content
	local cmdName = content:sub(#prefix + 1, cmdStart-1)
	local cmd = _M.list[cmdName:lower()]
	print(("cmd? %q"):format(cmdName),cmd and "found" or "not found")
	if not cmd then return end
	
	if not msg.member then return msg:reply("Sorry, this command can only be used in the Meta Construct Discord server.") end
	local args = content:Split(" ")
	table.remove(args, 1)
	local line = content:sub(cmdEnd + 1, -1)

	if cmd.roles then
		local ok

		for _, role in next, cmd.roles do
			if config.groups[role] then
				if msg.member:hasRole(config.groups[role]) then
					ok = true
					break
				end
			end
		end

		if not ok then return msg:reply("You cannot access this command!") end
	end

	cmd.callback(msg, args, line)
end)

_G.discord_commands = _M

return _M
