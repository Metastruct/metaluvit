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
local Redis  = require("redis")

local Levels = require("./utils").Levels
local Utils  = require("./utils")

local function _noop(err, res)
  if err then
    error("Logger Redis: " .. err)
  end
end

local _RedisLogger = Object:extend()

function _RedisLogger:initialize(options)

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

  if options.uds and type(options.uds) == "string" then
    self.uds = options.uds
  else
    if not options.host or type(options.host) ~= "string" then
      error("Logger redis: host must be defined")
    end
    self.host = options.host

    if options.port and type(options.port) ~= "number" then
      error("Logger redis: port must be a number")
    end
    self.port = options.port
  end

  if not options.cmd or type(options.cmd) ~= "string" then
    error("Logger redis: a command must be defined")
  end
  self.cmd = options.cmd

  if not options.key or type(options.key) ~= "string" then
    error("Logger redis: a key must be defined")
  end
  self.key = options.key

  self.reconnect = options.reconnect or false
  self.date = options.date

  self.client = Redis:new(self.uds or self.host, self.port, self.reconnect)
end

function _RedisLogger:log(n, level, s, ...)

  local final_level = self.level or self.parent_level

  if level.value <= final_level.value then
    if not self.date then
      self.client:command(self.cmd, self.key, Utils.finalStringWithoutDate(level, s, ...), _noop)
    else
      self.client:command(self.cmd, self.key, Utils.finalString(self.dateformat, level, s, ...), _noop)
    end
  end

end

function _RedisLogger:setParentLevel(level)
  self.parent_level = level
end

function _RedisLogger:close()
  self.client:disconnect()
end

return _RedisLogger
