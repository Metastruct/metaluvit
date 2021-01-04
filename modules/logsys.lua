
local Logger = require("logger")
local Path   = require("path")

Logger:new({ path = Path.join(process.cwd(), "config_logging.json") })

return Logger.getLogger("metaluvit")
