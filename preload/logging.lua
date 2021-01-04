local log = require'modules/logsys'
_G.loggedprint = function(...)
   log:info(...)
end
_G.log=log
