local _M={}
local hooks = {}

_M.hooks = hooks

function _M.add( eventName, name, func )

	if not hooks[ eventName ] then
			hooks[ eventName ] = {}
	end

	hooks[ eventName ][ name ] = func

end


function _M.remove( eventName, name )

	if not hooks[ eventName ] then return end

	hooks[ eventName ][ name ] = nil

end

local log = require'modules/logsys'

function _M.run( name, ... )

	local hooks = hooks[ name ]
	if ( hooks ~= nil ) then
	
		local ok, a, b, c, d, e

		for k, v in pairs( hooks ) do 
			
			ok, a, b, c, d, e = xpcall(v,debug.traceback, ... )
			if not ok then
				log:error(a)
				a = nil
			end
			if a~=nil then
				return a, b, c, d, e
			end
			
		end
	end 
	
end
_M.call=_M.run
_M.Call=_M.call
_M.Run=_M.run
_M.Add=_M.add
_M.Remove=_M.remove


return _M