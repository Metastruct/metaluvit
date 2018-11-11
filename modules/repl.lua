local repl = require("repl")

local ok, why = pcall(function()
    repl(nil, process.stdout).start()
end)
if not ok then
    print("REPL could not start.")
    print(why)
end
