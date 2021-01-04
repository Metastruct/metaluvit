-- Example

local discord = require'modules/discord'
local last_userid
local last_msgtime = 0

discord:on("messageCreate", function(msg)
	if msg.channel.id ~= "657993992365015062" then return end
	if msg.channel.type ~= 0 then return end
	local content = msg.content
	local userid = msg.author.id
	
	-- msg:delete()

end)
