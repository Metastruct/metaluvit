local string = require "string"
local table = require "table"
local util = require "./util"
local utils = require "utils"

local Formatting = {}

Formatting.Colors = {
	START = string.char(3),
	WHITE = '00',
	BLACK = '01',
	DARK_BLUE = '02',
	DARK_GREEN = '03',
	LIGHT_RED = '04',
	DARK_RED = '05',
	MAGENTA = '06',
	ORANGE = '07',
	YELLOW = '08',
	LIGHT_GREEN = '09',
	CYAN = '10',
	LIGHT_CYAN = '11',
	LIGHT_BLUE = '12',
	LIGHT_MAGENTA = '13',
	GRAY = '14',
	LIGHT_GRAY = '15',
}

Formatting.Styles = {
	BOLD = string.char(2),
	UNDERLINE = string.char(31),
	ITALIC = string.char(29),
	REVERSE = string.char(18),
	REVERSE_DEPRECATED = string.char(22),
	RESET = string.char(15),
}
local allstyles = ""
for name,style in pairs(Formatting.Styles) do
	allstyles = allstyles..style
end

Formatting.stripstyles = function(str)
	return str:gsub("["..allstyles.."]", "")
end

Formatting.stripbackgrounds = function(str)
	return str:gsub("("..Formatting.Colors.START.."%d%d?),%d%d?", "%1")
end

Formatting.stripcolors = function(str)
	str = Formatting.stripbackgrounds(str)
	return str:gsub(Formatting.Colors.START.."%d?%d?", "")
end

Formatting.strip = function(str)
	return Formatting.stripstyles(Formatting.stripcolors(str))
end

Formatting.colorize = function(text, color, background)
	return string.format("%s%s%s", 
		Formatting.Colors.START..color..(background and ","..background or ""),
		text,
		Formatting.Styles.RESET)
end

Formatting.stylize = function(text, style)
	return string.format("%s%s%s", style, text, style)
end

-- useful reference: https://github.com/bramus/ansi-php/blob/master/src/ControlSequences/EscapeSequences/Enums/SGR.php
local ANSI = {}
Formatting.ANSI = ANSI

ANSI.sgr = function (parameters)
	return string.char(27) .. '[' .. (parameters or '0') .. 'm'
end

ANSI.sgr_extended_foreground = function(extended_color_code)
	return "38;5;" .. tostring(extended_color_code)
end

ANSI.sgr_extended_background = function(extended_color_code)
	return "48;5;" .. tostring(extended_color_code)
end

ANSI.SGR_FOREGROUND_BASE = 30
ANSI.SGR_BRIGHT_FOREGROUND_BASE = 90
ANSI.SGR_BACKGROUND_BASE = 40
ANSI.SGR_BRIGHT_BACKGROUND_BASE = 100

ANSI.dark_fg = function(ansi_color_code)
	return ANSI.SGR_FOREGROUND_BASE + ansi_color_code
end
ANSI.bright_fg = function(ansi_color_code)
	return "1;" .. (ANSI.SGR_FOREGROUND_BASE + ansi_color_code)
end

ANSI.dark_bg = function(ansi_color_code)
	return ANSI.SGR_BACKGROUND_BASE + ansi_color_code
end
ANSI.bright_bg = function(ansi_color_code)
	return ANSI.SGR_BRIGHT_BACKGROUND_BASE + ansi_color_code
end

ANSI.BaseColors = {
	BLACK = 0,
	RED = 1,
	GREEN = 2,
	YELLOW = 3,
	BLUE = 4,
	MAGENTA = 5,
	CYAN = 6,
	WHITE = 7,
}

ANSI.ForegroundColors = {
	WHITE = ANSI.bright_fg(ANSI.BaseColors.WHITE),
	BLACK = ANSI.dark_fg(ANSI.BaseColors.BLACK),
	DARK_BLUE = ANSI.dark_fg(ANSI.BaseColors.BLUE),
	DARK_GREEN = ANSI.dark_fg(ANSI.BaseColors.GREEN),
	LIGHT_RED = ANSI.bright_fg(ANSI.BaseColors.RED),
	DARK_RED = ANSI.dark_fg(ANSI.BaseColors.RED),
	MAGENTA = ANSI.dark_fg(ANSI.BaseColors.MAGENTA),
	ORANGE = ANSI.dark_fg(ANSI.BaseColors.YELLOW),
	YELLOW = ANSI.bright_fg(ANSI.BaseColors.RED),
	LIGHT_GREEN = ANSI.bright_fg(ANSI.BaseColors.GREEN),
	CYAN = ANSI.dark_fg(ANSI.BaseColors.CYAN),
	LIGHT_CYAN = ANSI.bright_fg(ANSI.BaseColors.CYAN),
	LIGHT_BLUE = ANSI.bright_fg(ANSI.BaseColors.BLUE),
	LIGHT_MAGENTA = ANSI.bright_fg(ANSI.BaseColors.MAGENTA),
	GRAY = ANSI.bright_fg(ANSI.BaseColors.BLACK),
	LIGHT_GRAY = ANSI.dark_fg(ANSI.BaseColors.WHITE),
}
ANSI.BackgroundColors = {
	WHITE = ANSI.bright_bg(ANSI.BaseColors.WHITE),
	BLACK = ANSI.dark_bg(ANSI.BaseColors.BLACK),
	DARK_BLUE = ANSI.dark_bg(ANSI.BaseColors.BLUE),
	DARK_GREEN = ANSI.dark_bg(ANSI.BaseColors.GREEN),
	LIGHT_RED = ANSI.bright_bg(ANSI.BaseColors.RED),
	DARK_RED = ANSI.dark_bg(ANSI.BaseColors.RED),
	MAGENTA = ANSI.dark_bg(ANSI.BaseColors.MAGENTA),
	ORANGE = ANSI.dark_bg(ANSI.BaseColors.YELLOW),
	YELLOW = ANSI.bright_bg(ANSI.BaseColors.RED),
	LIGHT_GREEN = ANSI.bright_bg(ANSI.BaseColors.GREEN),
	CYAN = ANSI.dark_bg(ANSI.BaseColors.CYAN),
	LIGHT_CYAN = ANSI.bright_bg(ANSI.BaseColors.CYAN),
	LIGHT_BLUE = ANSI.bright_bg(ANSI.BaseColors.BLUE),
	LIGHT_MAGENTA = ANSI.bright_bg(ANSI.BaseColors.MAGENTA),
	GRAY = ANSI.bright_bg(ANSI.BaseColors.BLACK),
	LIGHT_GRAY = ANSI.dark_bg(ANSI.BaseColors.WHITE),
}

ANSI.Styles =
{
	BOLD = 1,
	UNDERLINE = 4,
	ITALIC = 3,
	REVERSE = 7,
	REVERSE_DEPRECATED = 7,
	RESET = 0,
}

Formatting.StyleConversion = {}
for style, ansi_style_code in pairs(ANSI.Styles) do
	local irc_style_code = Formatting.Styles[style]
	if irc_style_code ~= nil then
		Formatting.StyleConversion[irc_style_code] = ansi_style_code
	end
end

Formatting.ForegroundColorConversion = {}
for color, ansi_color_code in pairs(ANSI.ForegroundColors) do
	local irc_color_code = Formatting.Colors[color]
	if irc_color_code ~= nil then
		Formatting.ForegroundColorConversion[irc_color_code] = ansi_color_code
	end
end
Formatting.BackgroundColorConversion = {}
for color, ansi_color_code in pairs(ANSI.BackgroundColors) do
	local irc_color_code = Formatting.Colors[color]
	if irc_color_code ~= nil then
		Formatting.BackgroundColorConversion[irc_color_code] = ansi_color_code
	end
end

Formatting.normalize_color_code = function(color_code)
	if color_code:len() == 0 then
		color_code = Formatting.Styles.RESET
	elseif color_code:len() == 1 then
		color_code = '0'..color_code
	end
	return color_code
end

Formatting.convert = function(text)
	for style, conversion in pairs(Formatting.StyleConversion) do
		text = text:gsub(style, ANSI.sgr(conversion))
	end
	text = Formatting.stripstyles(text)
	local replacements = {}
	for colorstring, foreground, background in string.gmatch(text, "(" .. Formatting.Colors.START.."(%d?%d?),?(%d?%d?)" .. ")") do
		foreground = Formatting.ForegroundColorConversion[Formatting.normalize_color_code(foreground)]
		background = Formatting.BackgroundColorConversion[Formatting.normalize_color_code(background)]
		local conversion = ANSI.sgr(foreground .. (background and (";" .. background) or ""))
		table.insert(replacements, {needle=colorstring, replacement=conversion})
	end
	for _,replacement in ipairs(replacements) do
		text = util.string.findandreplace(text, replacement.needle, replacement.replacement)
	end
	return text..utils.color()
end

Formatting.print = function(text)
	print(Formatting.convert(text))
end

return Formatting