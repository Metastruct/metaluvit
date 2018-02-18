--[[
    Commands Engine.
    Engine that handles the commands and loads them.
]]

local discordia = require('discordia')

local fs = require('fs')

local function findRole(member,groups)
    local roles = member.roles[1]
    local dev = false
    local admin = false

    for k,v in next,roles do
        if(v == groups.devs) then
            dev = true
        end
        if(v == groups.admins) then
            admin = true
        end
    end

    return dev, admin
end

return function(object)
    local client = object.client
    object.commands = {}

    for k,v in pairs(fs.readdirSync('commands')) do
        local name = string.StripExtension( v )
        object.commands[name] = require("../commands/"..v)
    end

    _G.commands = {
        add = function(category,name,description,callback,owner,nsfw)
            if object.commands[category] == nil then
                object.commands[category] = {}
            end
            object.commands[category][name] = {
                nsfw = (nsfw == nil) and false or nsfw,
                protected = (owner == nil) and false or owner,
                description = tostring(description),
                callback = callback
            }
    
            return object.commands[category][name]
        end,
        remove = function(category,command)
            if object.commands[category] == nil or object.commands[category][command] == nil then
                return false,"not exists (cat. or command)"
            end

            object.commands[category][command] = nil
            return true
        end,
        list = object.commands
    }

    client:on("messageCreate", function(msg)
        for k,v in pairs(object.commands) do
            for cmd,obj in pairs(v) do
                local combine = object.prefix..cmd
                if msg.content:StartWith(combine.." ") or msg.content == combine then
                    local dev, admin = findRole(msg.member,object.groups)
                    if not dev then
                        msg:reply("You cannot access this command!")
                        return
                    end
                    if(obj.admin and not admin) then
                        msg:reply("This command is for `Administrator` role's users only.")
                        return
                    end
                    local args = string.Split(msg.content, " ")
                    table.remove(args,1)
                    local line = msg.content:sub((combine.." "):len(),msg.content:len())
                    local success,err = obj.callback(msg,args,line)
                end
            end
        end
    end)
end