--[[
    Commands engine.
    Engine that handles the commands and loads them.

    (for Discordia client)
]]

local fs = require("fs")

local config = _G.config -- clarify

local client = instances.discord

local commands = { list = {} }

function commands:add(category, name, description, callback, owner, nsfw)
    if self.list[category] == nil then
        self.list[category] = {}
    end

    self.list[category][name] = {
        nsfw = (nsfw == nil) and false or nsfw,
        protected = (owner == nil) and false or owner,
        description = tostring(description),
        callback = callback
    }

    return self.list[category][name]
end

function commands:remove(category, command)
    if self.list[category] == nil or self.list[category][command] == nil then
        return false, "category or command doesn't exist"
    end

    self.list[category][command] = nil
    return true
end

for k, v in pairs(fs.readdirSync("commands")) do
    local name = string.StripExtension(v)
    commands.list[name] = require("../commands/" .. v)
end

client:on("messageCreate", function(msg)
    for catName, cat in pairs(commands.list) do
        for cmdName, cmd in pairs(cat) do
            local args = string.Split(msg.content, " ")
            local prefix = msg.content:match("^" .. config.prefix)
            if not prefix then return end

            local match = args[1]:sub(#prefix + 1, #args[1])
            local ok = true
            if cmdName ~= match then ok = false end

            if ok then
                table.remove(args, 1)
                local line = table.concat(args, " ")

                if not msg.member then
                    return msg:reply("Sorry, commands can only be used in the Meta Construct Discord server.")
                end

                if cmd.admin then
                    if not msg.member:hasRole(config.groups.devs) then
                        return msg:reply("You cannot access this command!")
                    end

                    if cmd.admin and not msg.member:hasRole(config.groups.admins) then
                        return msg:reply("This command is for administrators only.")
                    end
                end

                local ok, why = cmd.callback(msg, args, line)
            end
        end
    end
end)

_G.commands = commands
