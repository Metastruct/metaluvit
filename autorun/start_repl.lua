local repl = require("repl")
local uv = require('uv')
local hook = require("modules/hook")
local log = require("modules/logsys")
local utils = require('utils')
if false then
	local stdin = uv.new_tty(0, true)
	local stdout = uv.new_tty(1, true)
	local debug = require('debug')
	local c = utils.color

	local function evaluateLine(line)
		if line == "exit\n" then
			print("I don't hate you...")
			process:exit(0)
			return '>'
		end
		
		if not hook.run("processConsoleInput",line) then 
			print"Unknown command"
		end


		return '>'
	end

	local function displayPrompt(prompt)
		uv.write(stdout, prompt .. ' ')
	end

	local function onread(err, line)
		if err then
			error(err)
		end

		if line then
			local prompt = evaluateLine(line)
			displayPrompt(prompt)
		else
			uv.close(stdin)
		end
	end

	coroutine.wrap(function()
		displayPrompt'>'
		uv.read_start(stdin, onread)
	end)()

	return
end

local stdin = uv.new_tty(0, true)

local ok, why = pcall(function()
	repl(stdin, process.stdout).start()
end)

if not ok then
	log:error("REPL could not start: " .. why)
end
