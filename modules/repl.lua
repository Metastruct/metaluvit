local repl = require("repl")

local ok, why = pcall(function()
    repl(process.stdin, process.stdout).start()
end)
if not ok then
    print("REPL could not start. Going to assume this is because luvit version is too new. (some knobhead manually placed dependencies in here)")
    print(why)
end
