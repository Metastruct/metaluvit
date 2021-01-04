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

-- vi /etc/rsyslog.conf
-- netstat -a | grep syslog
-- netstat -an | grep 514

local Object = require("core").Object
local String = require("string")
local DGram = require("dgram")
local Socket = require("dgram").Socket

local Levels = require("./utils").Levels

local function _noop() end

local _SyslogLogger = Object:extend()

function _SyslogLogger:initialize(options)

  self.type = options.type

  self.level = nil
  if type(options.level) == "string" and Levels[String.lower(options.level)] then
    self.level = Levels[String.lower(options.level)]
  end

  self.dateformat = nil
  if options.dateformat and type(options.dateformat) == "string" then
    self.dateformat = options.dateformat
  end

  self.parent_level = options.parent_level

  self.url = options.url
  self.cmd = options.cmd
  self.date = options.date

  self.port = options.port
  self.host = options.host

  self.socket = DGram.createSocket("udp4", function(err)
    error(err)
  end)
end

function _SyslogLogger:log(n, parent_level, level, s, ...)

  local final_level = self.level or self.parent_level

  if level.value > final_level.value then
    return
  end

  self.socket:send(s, self.port, self.host, _noop)
end

function _SyslogLogger:setParentLevel(level)
  self.parent_level = level
end

function _SyslogLogger:close()
  self.socket:close()
end

return _SyslogLogger
