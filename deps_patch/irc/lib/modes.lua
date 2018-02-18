local instanceof = require('core').instanceof
local util = require('./util')
local table = require "table"

local Modes = { flags = {} }

Modes.MODETYPE_USERLIST=1
Modes.MODETYPE_PARAM=2
Modes.MODETYPE_SETPARAM=3
Modes.MODETYPE_NOPARAM=4
Modes.MODETYPE_USERPREFIX=5

local Mode = require('core').Object:extend()

function Mode:initialize(flag, type, prefix)
	self.flag = flag
	self.type = type or Modes.MODETYPE_NOPARAM
	self.prefix = prefix
end

function Mode:set(channel, setby, params)
	if params and type(params) ~= "table" then params = {params} end
	local param = nil
	if self.type == Modes.MODETYPE_USERLIST then
		param = table.remove(params, 1)
	elseif self.type == Modes.MODETYPE_PARAM or self.type == Modes.MODETYPE_SETPARAM then
		param = table.remove(params, 1)
		channel.modes[self.flag] = param
	elseif self.type == Modes.MODETYPE_NOPARAM then
		channel.modes[self.flag] = true
	elseif self.type == Modes.MODETYPE_USERPREFIX then
		param = table.remove(params, 1)
		local user = channel:getuser(param)
		user.modes[self.flag] = true
		user.prefix = user.prefix..self.prefix
		user:emit("+mode", self, setby)
	end
	channel:emit("+mode", self, setby, param)
	return params
end

function Mode:unset(channel, setby, params)
	if params and type(params) ~= "table" then params = {params} end
	local param = nil
	if self.type == Modes.MODETYPE_USERLIST then
		param = table.remove(params, 1)
	elseif self.type == Modes.MODETYPE_PARAM then
		param = table.remove(params, 1)
		channel.modes[self.flag] = nil
	elseif self.type == Modes.MODETYPE_NOPARAM or self.type == Modes.MODETYPE_SETPARAM then
		channel.modes[self.flag] = nil
	elseif self.type == Modes.MODETYPE_USERPREFIX then
		param = table.remove(params, 1)
		local user = channel:getuser(param)
		user.modes[self.flag] = nil
		user.prefix = util.string.findandreplace(user.prefix, self.prefix, "")
		user:emit("-mode", self, setby)
	end
	channel:emit("-mode", self, setby, param)
	return params
end

function Modes.clear()
	local flagstoremove = {}
	for _,flag in ipairs(Modes.flags) do
		table.insert(flagstoremove, flag)
	end
	for _,flag in ipairs(flagstoremove) do
		Modes.remove(flag)
	end
end

function Modes.remove(flag)
	assert(Modes.get(flag) ~= nil)
	Modes[flag] = nil
	util.table.findandremove(Modes.flags, flag)
end

function Modes.add(flag, type, prefix)
	assert(Modes.get(flag) == nil, tostring(util.table.findbyvalue(Modes, type)).." mode "..flag.." already exists")
	Modes[flag] = Mode:new(flag, type, prefix)
	table.insert(Modes.flags, flag)
end

function Modes.get(flag)
	return Modes[flag]
end

function Modes.apply(channel, setby, flagstring, params)
	flags = util.string.split(flagstring, "")
	local setting = true
	for _,flag in ipairs(flags) do
		if flag == "+" then 
			setting = true
		elseif flag == "-" then 
			setting = false
		else
			local mode = Modes.get(flag)
			if mode ~= nil then
				if setting then
					mode:set(channel, setby, params)
				else
					mode:unset(channel, setby, params)
				end
			end
		end
	end
end

function Modes.getmodebyprefix(prefix)
	for _,flag in ipairs(Modes.flags) do
		if Modes.get(flag).prefix == prefix then
			return Modes.get(flag)
		end
	end
	return nil
end

function Modes.getprefixbyflag(flag)
	local mode = Modes.get(flag)
	return mode ~= nil and mode.prefix or nil
end

return Modes