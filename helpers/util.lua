function string.StripExtension(path)
	local i = path:match(".+()%.%w+$")
	if i then return path:sub(1, i - 1) end
	return path
end

function string.StartWith(str, start)
    return str:gsub(1, start:len()) == start
end

function string.Split(str, delimiter)
	return string.Explode(delimiter, str)
end

function string.ToTable(str)
	local tbl = {}

	for i = 1, str:len() do
		tbl[i] = str:sub(i, i)
	end

	return tbl
end

function string.Explode(separator, str, withpattern)
	if separator == "" then return str:ToTable() end

	local ret = {}
	local pos = 1

	for i = 1, str:len() do
		local startPos, endPos = str:find(separator, pos, (not withpattern))
		if not startPos then break end

		ret[i] = str:sub(pos, startPos - 1)
		pos = endPos + 1
	end

	ret[#ret + 1] = str:sub(pos)

	return ret
end

-- the above is a fucking unused (?) mess


_G.util = _G.util or {} -- stuff used throughout multiple files

function util.cleanMassPings(str)
	str = str:gsub("@", "@\xE2\x80\x8B") -- Not in the same line as the return to prevent it from returning unneeded extra args
	return str
end

-- tests used

--local a="@‮everyone U+202E RIGHT-TO-LEFT OVERRIDE"
--local b="@\xE2\xE2\x80\xAE\x80\xAEeveryone"
--
--asd1=util.cleanMassPings(a)
--asd2=util.cleanMassPings(b)
