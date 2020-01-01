-- experimental
local client = instances.discord
local last_userid
local last_msgtime = 0

client:on("messageCreate", function(msg)
	if msg.channel.id ~= "657993992365015062" then return end
	if msg.channel.type ~= 0 then return end
	local content = msg.content
	local userid = msg.author.id

	-- Undone: prevent multiline chatting
	
	-- TODO: find other ways to deter trolling
		
	if false then
		msg:delete()
	end
end)
