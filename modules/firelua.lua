local childProcess = require('childprocess')
local HOME = '/home/metaluvit'

local function runLua(data_input, cb, maxlen)
	local params = {'--quiet', '--timeout=00:00:06', '--cpu=2,3', '--rlimit-nproc=50', '--rlimit-fsize=' .. (1024 * 1024), '--rlimit-as=400000000', '--read-only=' .. HOME .. '/.luarocks', '--read-only=' .. HOME .. '/jail', '/usr/bin/luajit', HOME .. '/jail/runner.lua'}

	local options = {
		cwd = HOME .. '/jail'
	}

	local child = childProcess.spawn('/usr/bin/firejail', params, options)
	maxlen = maxlen or 21400
	local data = {}
	local datan = 0
	local datalen = 0
	local incomplete
	local dataErr = {}
	local datanErr = 0
	local datalenErr = 0
	local incompleteErr

	local function runCallback(return_code)
		if not cb then
			p("runCallback AGAIN?", return_code)

			return
		end

		local ok = return_code == 0 and not incomplete and not incompleteErr
		local output, errors = table.concat(data), table.concat(dataErr)

		local extra = {
			output_overflow = incomplete,
			errors_overflow = incompleteErr,
			return_code = return_code
		}

		local _callback_function_ = cb
		cb = nil
		_callback_function_(ok, output, #errors > 0 and errors, extra)
	end

	local function onStdout(chunk)
		p('data', #chunk)
		local newlen = datalen + #chunk

		if newlen >= maxlen then
			incomplete = true
			p("overflow", newlen, #chunk)
			child.stdout:destroy()
			child.stderr:destroy()
			child.stdin:destroy()
			child:close()
			runCallback(-27)
		end

		datan = datan + 1
		datalen = newlen
		data[datan] = chunk
	end

	local function onStderr(chunk)
		p('data err', #chunk)
		local newlen = datalenErr + #chunk

		if newlen >= maxlen then
			incompleteErr = true
			p("overflow", newlen, #chunk)
			child.stdout:destroy()
			child.stderr:destroy()
			child.stdin:destroy()
			child:close()
			runCallback(-27)
		end

		datanErr = datanErr + 1
		datalenErr = newlen
		dataErr[datanErr] = chunk
	end

	local function onClose(code, signal)
		p('close', code, signal)
	end

	local function onExit(code, signal)
		p('exit', code, signal)
		runCallback(code)
	end

	local function onEndErr()
		p("EOF ERR")
		child.stdin:destroy()
	end

	local function onEnd()
		p("EOF STD")
		child.stdin:destroy()
	end

	child:on('error', function(err)
		p("err", err)
		child:close()
	end)

	child:on('exit', onExit)
	child:on('close', onClose)
	child.stdout:on('end', onEnd)
	child.stdout:on('data', onStdout)
	child.stderr:on('end', onEndErr)
	child.stderr:on('data', onStderr)

	child.stdin:write(data_input, function(...)
		print("wrote?", ...)
	end)

	child.stdin:destroy()
end

--runLua([[--
--io.stderr:write("hello\nworld\n")
--io.stderr:flush()
--for i=1,2223 do
--	print("wtffffffffffffff")
--end
--]],p)
--channel:send {
--  content = "local foo = 'bar'",
--  code = "lua"
--}
local _M = {}
_M.run = runLua

return _M
