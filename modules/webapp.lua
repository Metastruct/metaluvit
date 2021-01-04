local json = require("json").use_lpeg()
require("weblit-websocket")
local discord = require'modules/discord'
local client = discord.client

local function errorEmbed(...)
	return {
		embed = {
			title = "Error:",
			description = "```" .. tostring(...):sub(0, 2000) .. "```",
			color = 0xff0000
		}
	}
end

local function handleWS(data, write)
	if data == nil then
		log:debug("handleWS","???",tostring(write))
	else
		log:debug("handleWS",tostring(data))	
	end
	
	local data_json,err = json.parse(data)

	hook.run("ws",data,write,data_json)
	
end

local cached_emojistr
local function getEmojisString()
	if cached_emojistr then return cached_emojistr end
	cached_emojistr=""
	
	local emojis = {}

	for emoji in discord.guild.emojis:iter() do
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
	cached_emojistr = json.stringify(emojis)
	return cached_emojistr
end



local app = require("weblit-app").bind({
	host = "127.0.0.1",
	port = 20123
}).use(require("weblit-logger")).use(require("weblit-auto-headers")).websocket({
	path = "/metaluvit/v2/socket"
}, function(req, read, write)
	local ip = req.socket:getpeername().ip
	log:debug("New client",ip)
	
	local here = false

	for _, data in pairs(config.gameservers) do
		if ip == data.ip or ip == "::1" or ip == "::" or ip == "127.0.0.1" then
			here = true
		end
	end

	if not here then
		log:debug("Unknown IP: ", ip)

		return write()
	end

	for message in read do
		message.mask = nil
		local ok, why = xpcall(handleWS,debug.traceback, message.payload, write)

		if not ok then
			log:error("handleWS",why)
		end

	end

	log:debug("Client",ip," left")

	return write()
end).route({
	method = "GET",
	path = "/discord/guild/emojis"
}, function(req, res, go)

	res.body = getEmojisString()
	res.code = 200
	res.headers["Content-Type"] = "application/json"
end)


return app
