
local cmds = require'modules/discord_commands'
local firelua = require'modules/firelua'
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
				local content = reply
							
				-- prevent escaping from the code quotes...
				content = content:gsub("`", "\\`")
				content = content:gsub("*", "\\*")
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
