local json = require("json").use_lpeg()

local function errorEmbed(...)
	return {
		embed = {
			title = "Error:",
			description = "```" .. tostring(...):sub(0, 2000) .. "```",
			color = 0xff0000
		}
	}
end

local client = instances.discord
local webhook = string.Split(config.webhook, "/")
local function execWebhook(tbl)
	return client and client._api:executeWebhook(webhook[1], webhook[2], tbl)
end

local status = {}

local evts = {
	status = function(serverID, data)
		status[serverID] = data.status
	end,
	msg = function(serverID, data)
		if webhook then
			-- local file = image.getByURL(data.msg.avatar or "http://i.imgur.com/ovW4MBM.png")
			coroutine.wrap(function()
				local msg = data.msg.txt
				if not msg then return end

				msg = util.cleanMassPings(msg)

				if msg:match("@%w+") then
					for mention in msg:gmatch("@(%w+)") do
						local uid = findDiscordUserID(mention)
						if uid then
							msg = msg:gsub("@" .. mention, "<@" .. uid .. ">")
						end
					end
				end

				local username = #data.msg.nickname > 26 and (data.msg.nickname:sub(1, 26) .. "...") or data.msg.nickname

				execWebhook({
					username = serverID .. " " .. username,
					avatar_url = data.msg.avatar or "http://i.imgur.com/ovW4MBM.png",
					content = msg
				})
			end)()
		end
	end,
	disconnect = function(serverID, data)
		coroutine.wrap(function()
            config.channel:send({
                embed = {
                    author = {
                        icon_url = data.disconnect.avatar or "http://i.imgur.com/ovW4MBM.png",
                        name = data.disconnect.nickname .. " has left the server.",
                        url = "http://steamcommunity.com/profiles/" .. data.disconnect.steamid
                    },
                    fields = data.disconnect.reason ~= "" and {
                        [1] = {
                            name = "Reason:",
                            value = data.disconnect.reason
                        }
                    },
                    footer = {
                        text = "Server " .. serverID
                    },
                    color = 0xB54343
                }
            })
		end)()
	end,
	spawn = function(serverID, data)
		coroutine.wrap(function()
            config.channel:send({
                embed = {
                    author = {
                        icon_url = data.spawn.avatar or "http://i.imgur.com/ovW4MBM.png",
                        name = data.spawn.nickname .. " has spawned.",
                        url = "http://steamcommunity.com/profiles/" .. data.spawn.steamid
                    },
                    footer = {
                        text = "Server " .. serverID
                    },
                    color = 0x4BB543
                }
            })
		end)()
	end,
	shutdown = function(serverID, data)
		_G.status[serverID] = { players = {}, title = "Meta Construct " .. serverID, map = "gm_unknown" }
        coroutine.wrap(function()
            config.channel:send({
                embed = {
                    title = "Server " .. serverID .. " shutting down...",
                    description = "Resetting status...",
                    footer = {
                            text = "Server " .. serverID
                    },
                    color = 0x0275d8
                }
            })
        end)()
	end,
	notify = function(serverID, data)
		if not data.notify.text then return end
        coroutine.wrap(function()
            config.channel:send({
                embed = {
                    title = data.notify.title or "",
                    description = data.notify.text,
                    footer = {
                        text = "Server " .. serverID
                    },
                    color = data.notify.color or 0xffff00
                }
            })
        end)()
	end,
	webhook = function(serverID, data)
		if type(data.webhook) ~= "table" or next(data.webhook) == nil then return end

        local wh = data.webhook
        if wh.content or wh.embeds then
            wh.content = wh.content and util.cleanMassPings(wh.content)
            coroutine.wrap(function()
                local ok, why = execWebhook(wh)
                if not ok then config.channel:send(errorEmbed(why)) end
            end)()
        else
            coroutine.wrap(function()
                config.channel:send(errorEmbed("Received invalid embed?") )
            end)()
        end
	end
}

local function handleWS(data, write)
	if data == nil then return end

	if type(data) == "string" then
		data = json.parse(data) or {}
	end
	local server = "#" .. (data.server or "-1")

	for name in next, data do
		if evts[name] then
			evts[name](server, data)
		end
	end
end

require("weblit-websocket")
local app = require("weblit-app")
	.bind({ host = "0.0.0.0", port = 20122 })

	.use(require("weblit-logger"))
	.use(require("weblit-auto-headers"))

	.websocket({ path = "/v2/socket" },	function(req, read, write)
		print("New client")
		print("Checking IP...")

		local here = false
		for _, data in pairs(config.gameservers) do
			local ip = req.socket:getpeername()
			if ip == data.ip or ip == "::1" or ip == "::" or ip == "127.0.0.1" then
				here = true
			end
		end

		if not here then
			print("Unknown IP: ", req.socket:getpeername())
            for k,v in next,req.socket:getpeername() do
                print(k,"=",v)
            end
			return write()
		end

		for message in read do
			message.mask = nil

            local ok, why = pcall(handleWS, message.payload, write)
			if not ok then print(why) end

			write(message)
		end

		print("Client left")
		return write()
	end)

    .route({ method = "GET", path = "/discord/guild/emojis" }, function(req, res, go)
        local emojis = {}
        for emoji in config.guild.emojis:iter() do
            emojis[tostring(emoji.id)] = {
                createdAt = emoji.createdAt,
                id = tostring(emoji.id),
                timestamp = emoji.timestamp,
                animated = emoji.animated,
                mentionString = emoji.mentionString,
                name = emoji.name,
                url = emoji.url
            }
        end

        res.body = json.stringify(emojis)
        res.code = 200
        res.headers["Content-Type"] = "application/json"
    end)

app.serverStatus = status

local timer = require("timer")
timer.setInterval(10000, function()
	if client and status then
		local str = ""
		for id, data in next, status do
			str = str .. (data.players and #data.players or "0") .. " players on " .. id .. " | "
		end
		str = str .. "!status"

		coroutine.wrap(function()
			client:setGame(str)
		end)()
	end
end)

return app