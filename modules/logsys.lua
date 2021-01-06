if not package.loaded.redis then
	package.preload.redis=function() return {} end
end
local Logger = require("logger")

local Path   = require("path")

Logger:new({ path = Path.join(process.cwd(), "config_logging.json") })

local log = Logger.getLogger("metaluvit")

-- legacy
_G.loggedprint = function(msg,...)
	local concated={tostring(msg)}
	for i=1,select('#',...) do
		local v=select(i,...)
		v=tostring(v) or "no value"
		concated[i+1]=v
	end
	msg = table.concat(concated,"\t")
	log:logn(1,Logger.INFO,msg)
end
local _M={}


local levels = {
  error = {value = 0, name = "ERROR"},
  warn  = {value = 1, name = "WARN"},
  info  = {value = 2, name = "INFO"},
  debug = {value = 3, name = "DEBUG"},
  trace = {value = 4, name = "TRACE"}
}

for level,data in pairs(levels) do
	local levelid = Logger[data.name]
	
	_M[level]=function(_,msg,...)
		if not msg:find("%",1,true) then
			local concated={msg}
			for i=1,select('#',...) do
				local v=select(i,...)
				v=tostring(v) or "no value"
				concated[i+1]=v
			end
			msg = table.concat(concated,"\t")
			log:logn(1,levelid,msg)
		end
	end
	_M[level..'n']=function(_,n,msg,...)
		if not msg:find("%",1,true) then
			local concated={msg}
			for i=1,select('#',...) do
				local v=select(i,...)
				v=tostring(v) or "no value"
				concated[i+1]=v
			end
			msg = table.concat(concated,"\t")
			log:logn(n+1,levelid,msg)
		end
	end
end


return _M
