  --[[lit-meta
    name = "metaluvit"
    version = "0.0.1"
    dependencies = {}
    description = "Metastruct Luvit Based Daemon"
    tags = { "metastruct", "chat", "luvit" }
    license = "MIT"
    author = { name = "Metastruct", email = "metastruct@metastruct.uk.to" }
    homepage = "https://metastruct.net"
  ]]
  
local serverid = os.getenv("DISCORDGUILD")
local channelid = os.getenv("DISCORDCHANNEL")

if not serverid or not channelid then
	p "Please setup env. variables: DISCORDGUILD, DISCORDCHANNEL."
	p "One of them is not set up."
	p "Crashing..."
	process.exit(1)
end

local discordia = require('discordia')
local client = discordia.Client()
local IRC=require ('irc')

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

--[[
local json = require('json')
local weblit = require('weblit')

local wlit = weblit.app
	.bind({host = "0.0.0.0", port = 20122})

	.use(weblit.logger)
	.use(weblit.autoHeaders)
	.use(weblit.websocket)


	.websocket({
	  path = "/v2/socket",
	  protocol = "virgo/2.0"
	}, function (req, read, write)
	  -- Log the request headers
	  p(req)
	  -- Log and echo all messages
	  for message in read do
		write(message)
	  end
	  -- End the stream
	  write()
	end)
	.route({ path = "/:name"}, function (req, res)
		res.body = req.method .. " - " .. req.params.name .. "\n"
		res.code = 200
		res.headers["Content-Type"] = "text/plain"
	end)
	.start()
]]

local c = IRC:new ("irc.3kv.in", "M", {auto_connect=true, auto_join={"#metastruct"}})
local guild
local channel

client:on('ready', function()
	guild = client:getGuild(serverid)
	channel = guild:getChannel(channelid)
	print('Logged in as '.. client.user.username)
end)

client:on('messageCreate', function(message)
	if message.channel == channel and message.author ~= client.user then
		if message.content:starts(".") then
			c:say("#metastruct", "Command call requested by "..message.author.username..":")
			c:say("#metastruct", message.content)
		else
			local attachments = message.attachment
			attachments = attachments and table.concat(attachments, ", ") or ""
			c:say("#metastruct", "<"..message.author.username.."> "..message.content .. attachments)
		end
	end
	
	if message.content == '!ping' then
		message.channel:send('Pong!')
	end
end)

c:on ("message", function (from, to, msg)
	print ("["..to.."] <"..from.."> "..IRC.Formatting.convert(msg))
	
	if(from ~= "M" and to == "#metastruct") then
		--wbclient:setName(from)
		coroutine.wrap(function()
			local id = "**<"..from..">** "
			local safemessage = tostring(IRC.Formatting.strip(msg))
			if from:find'meta[0-3]' and safemessage:find'^#' then
				id = ""
			end
			channel:send(id..safemessage)
		end)()
	end
end)

c:on ("connecting", function(nick, server, username, real_name)
        print(string.format("Connecting to %s as %s...", server, nick))
end)
c:on ("connect", function (welcomemsg, server, nick)
        print(string.format("Connected to %s as %s", server, nick))
end)
c:on ("connecterror", function (err)
        print(string.format("Could not connect: %s", err))
end)
c:on ("error", function (...)
        p (...)
        process.exit (1)
end)
c:on ("notice", function (from, to, msg)
        from = from or c.server
        print(string.format("-%s:%s- %s", from, to, msg))
end)
c:on ("data", function (...)
        --p (...)
end)
c:on ("ijoin", function (channel, whojoined)
        print(string.format("Joined channel: %s", channel))

        channel:on("join", function(whojoined)
                print(string.format("[%s] %s has joined the channel", channel, whojoined))
        end)
        channel:on("part", function(who, reason)
                print(string.format("[%s] %s has left the channel", channel, who)..(reason and " ("..reason..")" or ""))
        end)
        channel:on("kick", function(who, by, reason)
                print(string.format("[%s] %s has been kicked from the channel by %s", channel, who, by)..(reason and " ("..reason..")" or ""))
        end)
        channel:on("quit", function(who, reason)
                print(string.format("[%s] %s has quit", channel, who)..(reason and " ("..reason..")" or ""))
        end)
        channel:on("kill", function(who)
                print(string.format("[%s] %s has been forcibly terminated by the server", channel, who))
        end)
        channel:on("+mode", function(mode, setby, param)
                if setby == nil then return end
                print(string.format("[%s] %s sets mode: %s%s",
                        channel,
                        setby,
                        "+"..mode.flag,
                        (param and " "..param or "")
                ))
        end)
        channel:on("-mode", function(mode, setby, param)
                if setby == nil then return end
                print(string.format("[%s] %s sets mode: %s%s",
                        channel,
                        setby,
                        "-"..mode.flag,
                        (param and " "..param or "")
                ))
        end)
end)
c:on ("ipart", function (channel, reason)
        print(string.format("Left channel: %s", channel.name))
end)
c:on ("ikick", function (channel, kickedby, reason)
        print(string.format("Kicked from channel: %s by %s (%s)", channel.name, kickedby, reason))
end)
c:on ("names", function(channel)
        print("Users in channel "..tostring(channel)..":")
        for nick,user in pairs(channel.users) do
                print(" "..tostring(user))
        end
end)
c:on ("pm", function (from, msg)
        print ("<"..from.."> "..IRC.Formatting.convert(msg))
end)
c:on ("disconnect", function (reason)
        print (string.format("Disconnected: %s", reason))
end)
c:on ("unhandled", function(msg)
        p("Unhandled message", msg)
end)

local os = require'os'
if os.getenv"DISCORDKEY" then
	client:run('Bot '..os.getenv("DISCORDKEY"))
else
	print"NO DISCORD KEY"
end

print"Initialized"
