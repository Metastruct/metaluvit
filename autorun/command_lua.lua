
local cmds = require'modules/discord_commands'
local firelua = require'modules/firelua'


local function discordEscapeCodeMinimally(str)
	local ok, n1

	-- Strip bad combinations until they no longer exist or until we have iterated too many times
	for i = 1, 8192 do
		str, n1 = str:gsub("```", "`\xE2\x80\x8B``")

		if n1 == 0 then
			ok = true
			break
		end
	end

	if not ok then return (str:gsub("`", "`\xE2\x80\x8B")) end
	
	return str
end

cmds:add("lua",
	function(msg, args, line)
		line=line:gsub("```lua[\r\n][\r\n]?(.+)```","%1")
		print("firelua",(("%q"):format(line)),
		firelua.run(line,function(ok,reply,err,extra)
			if ok then
				if err then
					reply = reply ..'\n'..err
				end
			else
				reply = "error: "..tostring(err)..'\n'..tostring(extra.return_code)
			end
			
			coroutine.wrap(function()
				local content = discordEscapeCodeMinimally(reply)
				msg:reply{
					content = content,
					code = "lua",
					allowed_mentions = { parse = {} },
				}
			end)()

		end))
		return true
	end,
	{
		description = "Run lua",
		roles={"devs"}
	})
