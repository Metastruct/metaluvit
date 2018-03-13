local http = require("coro-http")
local fs = require("fs")
local timer = require('timer')
local os = require('os')

_G.image = {}

local fs = require("fs")
local path = require("path")
local temp_dir = path.join(process.cwd(), 'files/tmp/')
local base64 = require("base64")

if (fs.existsSync(temp_dir) ~= true) then
    fs.mkdirSync(temp_dir)
end

function image.getDiscordImageURL(msg,args)
    local link

    if(string.StartWith(tostring(args[1]),"http") or msg.content:match('https?://[%w-_%.%?%.:/%+=&]+')) then
        link = args[1] or msg.content:match('https?://[%w-_%.%?%.:/%+=&]+')
        print("Link found")
    elseif(msg.attachment or msg.attachments) then
        local url
        if msg.attachments then
            url = msg.attachments[1].url
        else
            url = msg.attachment.url
        end
        link = url
        print("Attachment found")
    elseif(msg.mentionedUsers and msg.mentionedUsers[1]) then
        local meme = msg.mentionedUsers[1][1]
        local avatar = "https://cdn.discordapp.com/avatars/"..meme.id.."/"..meme.avatar..".webp?size=1024"
        link = avatar
        print("Mention found")
    else
        local channel = msg.channel
        local messages = channel:getMessages(15)[2]
        for k,v in pairs(messages) do
            if v.content:match('https?://[%w-_%.%?%.:/%+=&]+') then
                link = v.content:match('https?://[%w-_%.%?%.:/%+=&]+')
                print("Link from other message found")
            elseif(v.attachment or v.attachments) then
                local url
                if v.attachments then
                    url = v.attachments[1].url
                else
                    url = v.attachment.url
                end
                link = url
                print("Attachment from the other message found")
            end
        end
    end

    if(link == nil) then
        link = "https://cdn.discordapp.com/avatars/"..msg.author.id.."/"..msg.author.avatar..".webp?size=1024"
        print("Nothing got found :( Using author's avatar instead.")
    end

    return link
end

function image.getByURL(url)
    local res,body = http.request("GET", url)
    return base64.encode(body)
end