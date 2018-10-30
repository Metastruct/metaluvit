local repl = require("repl")

local ok, why = pcall(function()
    repl(process.stdin, process.stdout).start()
end)
if not ok then
    print("REPL could not start. Going to assume this is because luvit version is too new and/or deps are mangled.")
    print(why)
end
