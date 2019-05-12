local function getDiscordNick(id)
	local member = config.guild.members:find(function(member)
		return member.id == id
	end)
	return member and member.name or "???"
end

local function findDiscordUserID(name)
	local member = config.guild.members:find(function(member)
		return member.name == name
	end)
	return member and member.id
end

local irc = require("irc")

-- IRC relaying
local c = instances.irc

local function handleIRC(from, to, msg)
	local id = "**<" .. from .. ">** "
	if msg:match("@%w+") then
		for mention in msg:gmatch("@(%w+)") do
			local uid = findDiscordUserID(mention)
			if uid then
				msg = msg:gsub("@" .. mention, "<@" .. uid .. ">")
			end
		end
	end
	local safemessage = tostring(irc.Formatting.strip(msg))
	if from:match("meta[0-3]") and safemessage:match("^#") then
		id = ""
	end

	-- Discord Markdown escape
	safemessage = util.cleanMassPings(safemessage)
	safemessage = safemessage:gsub("`", "\\`")
	--safemessage = safemessage:gsub("_", "\\_") -- breaks urls
	safemessage = safemessage:gsub("*", "\\*")

	pcall(function()
		config.channel:send(id .. safemessage)
	end)
end

c:on("message", function(from, to, msg)
	if (from ~= "Discord" and to == "#metastruct" and config.enabled and not from:match("^meta")) then
		coroutine.wrap(function()
            handleIRC(from, to, msg)
        end)()
	end
end)

-- Discord relaying
local client = instances.discord

client:on("messageCreate", function(msg)
	if msg.channel == config.channel and msg.author ~= client.user and config.enabled and msg.author.discriminator ~= "0000" then
		if msg.content:match("^%.") and msg.content ~= ".status" and msg.content:len() > 1 then
			c:say("#metastruct", "Command call requested by " .. msg.member.name .. "#" .. msg.author.discriminator .. ":")
			c:say("#metastruct", msg.content)
		else
			local hasAttachment = msg.attachment
			local attachments = "\n"
			local skip = false
			if hasAttachment then
				skip = true
				if msg.attachments then
					for i, attachment in next, msg.attachments do
						attachments = attachments .. attachment.url .. (i > 1 and  " , " or "")
					end
				else
					attachments = msg.attachment.url
				end
			end

			local hasEmbeds = msg.embeds
			local embeds = attachments
			if hasEmbeds and not skip then -- TODO: make sparate function to handle all objects
				for _, embed in next, msg.embeds do
					embeds = embeds
                          .. (embed.title and embed.title .. " " or "")
					      .. (embed.description and embed.description or "" .. "\n")
				end
			end

			local content = msg.content
			content = content:gsub("<@!?(%d-)>", function(id) -- get nickname from id
				return "@" .. getDiscordNick(id)
			end)
			content = content:gsub("<a?(:.-:)%d->", function(id) -- format emotes
				return id
			end)

			c:say("#metastruct", "[" .. msg.member.name .. "] " .. content .. embeds ..  attachments)
		end
	end
end)
