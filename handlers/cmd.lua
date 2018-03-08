--[[
    Commands Engine.
    Engine that handles the commands and loads them.
]]

local discordia = require('discordia')

local fs = require('fs')

return function(object,callback)
    local client = object.client
    object.commands = object.commands or {}

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
                    if not obj.forusers then
                        if not msg.member:hasRole(object.groups.devs) then
                            msg:reply("You cannot access this command!")
                            return
                        end
                        if(obj.admin and not msg.member:hasRole(object.groups.admins)) then
                            msg:reply("This command is for `Administrator` role's users only.")
                            return
                        end
                    end
                    local args = string.Split(msg.content, " ")
                    table.remove(args,1)
                    local line = msg.content:sub((combine.." "):len(),msg.content:len())
                    local success,err = obj.callback(msg,args,line,object)
                end
            end
        end
    end)
    if callback then callback() end
end
