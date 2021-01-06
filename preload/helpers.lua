
_G.config 		= require("config")
_G.hook			= require'modules/hook'
_G.util			= require'modules/util'
local debug = require('debug')

include=dofile
PrintTable=p

local filename="?"
local function trace(err)
	local errstr = debug.traceback(err)
	log:errorn(2,"Autorun error in ("..filename.."): "..errstr)
	return errstr
end

local fs = require'fs'
function RunAutorun()
	local autorun = fs.readdirSync("autorun/")
	table.sort(autorun)
	for _,file in pairs(autorun) do
		if file:find("%.lua$") then
			filename=file
			xpcall(dofile,trace,"autorun/"..file)
		end
	end
end
