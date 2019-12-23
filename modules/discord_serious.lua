-- experimental
local client = instances.discord
local last_userid
local last_msgtime = 0

client:on("messageCreate", function(msg)
	if msg.channel.id ~= "657993992365015062" then return end
	if msg.channel.type ~= 0 then return end
	local content = msg.content
	local userid = msg.author.id

	local now = os.clock()
	if last_userid == userid and (now-last_msgtime)<5 then
		print("Censoring", userid, content)
		msg:delete()
		return
	end

	last_userid = userid
	last_msgtime = now

	if content:find"^%:[^%:]+%:$" then
		print("Censoring", userid, content)
		msg:delete()

		return
	end
end)