local repl = require("repl")

local ok, why = pcall(function()
    repl(nil, process.stdout).start()
end)
if not ok then
    log:error("REPL could not start.")
    log:error(why)
end
