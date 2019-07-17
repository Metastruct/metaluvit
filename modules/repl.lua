local repl = require("repl")

local ok, why = pcall(function()
    repl(nil, process.stdout).start()
end)
if not ok then
    loggedprint("REPL could not start.")
    loggedprint(why)
end
