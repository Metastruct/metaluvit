local string = require "string"
local table = require "table"
local utils = {}
utils.string = {}
utils.table = {}

-- Compatibility: Lua-5.0
utils.string.split = function (str, delim, maxNb)
	-- Allow splitting at each char
	if delim == "" then
		local chararray = {}
		for char in str:gmatch"." do
    		table.insert(chararray, char)
		end
		return chararray
	end
	-- Eliminate bad cases...
	if string.find(str, delim) == nil then
		return { str }
	end
	if maxNb == nil or maxNb < 1 then
		maxNb = 0		-- No limit
	end
	local result = {}
	local pat = "(.-)" .. delim .. "()"
	local nb = 0
	local lastPos
	for part, pos in string.gmatch(str, pat) do
		nb = nb + 1
		result[nb] = part
		lastPos = pos
		if nb == maxNb then break end
	end
	-- Handle the last field
	if nb ~= maxNb then
		result[nb + 1] = string.sub(str, lastPos)
	end
	return result
end

utils.string.join = function (stringlist, delimiter)
	delimiter = delimiter or ""
	local len = #stringlist
	if len == 0 then 
		return "" 
	end
	local string = stringlist[1]
	for i = 2, len do 
		string = string .. delimiter .. stringlist[i] 
	end
	return string
end

utils.string.findandreplace = function (haystack, needle, replacement)
	local starti,endi = haystack:find(needle, 1, true)
	return haystack:sub(1,starti-1)..replacement..haystack:sub(endi+1)
end

utils.table.slice = function (values,i1,i2)
	local res = {}
	local n = #values
	-- default values for range
	i1 = i1 or 1
	i2 = i2 or n
	if i1 < 0 then
		i1 = n + i1 + 1
	end
	if i2 < 0 then
		i2 = n + i2
	elseif i2 > n then
		i2 = n
	end
	if i1 < 1 or i1 > n then
		return {}
	end
	local k = 1
	for i = i1,i2 do
		res[k] = values[i]
		k = k + 1
	end
	return res
end

utils.table.fallback = function (settings, defaults)
	for key,value in pairs(defaults) do
		if settings[key] == nil then
			settings[key] = value
		end
	end
end

utils.table.contains = function(tbl, value)
	return utils.table.findbyvalue(tbl, value) ~= nil
end

utils.table.findbyvalue = function(tbl, value)
	if tbl then
		for i,v in pairs(tbl) do
			if v == value then
				return i
			end
		end
	end
end

utils.table.findandremove = function (tbl, value)
	local key = utils.table.findbyvalue(tbl, value)
	if key then
		if #tbl > 0 then
			table.remove(tbl, key)
		else
			table[key] = nil
		end
	end
end

return utils