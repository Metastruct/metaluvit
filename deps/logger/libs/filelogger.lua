--[[

The MIT License (MIT)

Copyright (c) 2015 gsick

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

--]]

local Object = require("core").Object
local String = require("string")
local Print  = require("pretty-print")
local FS     = require("fs")
local Path   = require("path")

local Levels = require("./utils").Levels
local Utils  = require("./utils")

local function _noop(err)
  if err then
    error("Logger error: " .. err.message)
  end
end

local _FileLogger = Object:extend()

function _FileLogger:initialize(options)

  self.type = options.type

  self.level = nil
  if type(options.level) == "string" and Levels[String.lower(options.level)] then
    self.level = Levels[String.lower(options.level)]
  end

  self.dateformat = nil
  if options.dateformat and type(options.dateformat) == "string" then
    self.dateformat = options.dateformat
  end

  self.func_info = options.func_info
  self.parent_level = options.parent_level

  if type(options.path) ~= "string" then
    error("path: " .. Print.dump(options.path) .. " is not a string")
  end

  local is_absolute = options.path:sub(1, 1) == Path.sep
  if not is_absolute then
    self.path = Path.join(process.env.PWD, options.path)
  else
    self.path = options.path
  end

  local dirname = Path.dirname(self.path)
  if not FS.accessSync(dirname) then
    local success, err = FS.mkdirp(dirname, "0740")
    if err then
      error("dir: " .. Print.dump(dirname) .. " cannot be created")
    end
    self.fd = FS.openSync(self.path, "a", "0640")
  else
    self.fd = FS.openSync(self.path, "a", "0640")
  end

  self.sync = options.sync or false
end

function _FileLogger:log(n, level, s, ...)

  local final_level = self.level or self.parent_level

  if level.value <= final_level.value then
    local final_string = self.func_info
      and Utils.finalStringWithFuncInfo(n + 1, self.dateformat, level, s, ...)
      or Utils.finalString(n + 1, self.dateformat, level, s, ...)

    if self.sync then
      FS.writeSync(self.fd, 0, final_string .. "\n")
    else
      FS.write(self.fd, 0, final_string .. "\n", _noop)
    end
  end
end

function _FileLogger:setParentLevel(level)
  self.parent_level = level
end

function _FileLogger:close()
  FS.closeSync(self.fd)
end

return _FileLogger
