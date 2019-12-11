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
	local ok, n1, n2, n3

	-- Strip bad combinations until they no longer exist or until we have iterated too many times
	for i = 1, 32 do
		str, n1 = str:gsub("%\xE2%\x80%\xAE", "") -- escape RTL chars that discord removes: https://github.com/Eufranio/MagiBridge/blob/6a946b0b32347b107b57fa947410d772104003ff/src/main/java/com/magitechserver/magibridge/discord/DiscordMessageBuilder.java#L32
		str, n2 = str:gsub("@+([Ee][Vv][Ee][Rr][Yy][Oo][Nn][Ee])", "%1")
		str, n3 = str:gsub("@+([Hh][Ee][Rr][Ee])", "%1")

		if n1 + n2 + n3 == 0 then
			ok = true
			break
		end
	end

	if not ok then return (str:gsub("[^a-zA-Z0-9]", "")) end
	str = str:gsub("@", "\xE2\x80\x8B@\xE2\x80\x8B")
	
	return str
end

-- tests used

--local a="@‮everyone U+202E RIGHT-TO-LEFT OVERRIDE"
--local b="@\xE2\xE2\x80\xAE\x80\xAEeveryone"
--
--asd1=util.cleanMassPings(a)
--asd2=util.cleanMassPings(b)
