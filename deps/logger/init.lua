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

local Configuration = require("./libs/configuration")
local Levels        = require("./libs/utils").Levels
local ConsoleLogger = require("./libs/consolelogger")
local FileLogger    = require("./libs/filelogger")
local RedisLogger   = require("./libs/redislogger")
local SyslogLogger  = require("./libs/sysloglogger")

local _Logger = Object:extend()

function _Logger:initialize(options)

  self.name = options.name

  self.level = options.level and Levels[String.lower(options.level)] or Levels["error"]
  self.dateformat = nil
  if options.dateformat and type(options.dateformat) == "string" then
    self.dateformat = options.dateformat
  end

  self.loggers = {}
  if type(options.loggers) ~= "table" then
    error("Loggers: " .. Print.dump(options.loggers) .. " is not a table")
  end
  for index, value in ipairs(options.loggers) do

    local logger
    local options = value
    if type(options.type) ~= "string" then
      error("logger type: " .. Print.dump(options.type) .. " is not a string")
    end

    if not options.dateformat then
      options.dateformat = self.dateformat
    end

    options.parent_level = self.level

    if options.type == "file" then
      logger = FileLogger:new(options)
    elseif options.type == "console" then
      logger = ConsoleLogger:new(options)
    elseif options.type == "redis" then
      logger = RedisLogger:new(options)
    elseif options.type == "syslog" then
      logger = SyslogLogger:new(options)
    else
      error("logger type: " .. Print.dump(options.type)
        .. " should be \"file\", \"console\", \"redis\" or \"syslog\"")
    end

    self.loggers[index] = logger
  end
end

function _Logger:getName()
  return self.name
end

function _Logger:setLevel(level)
  local done = false
  if type(level) == "string" and Levels[String.lower(level)] ~= nil then
    self.level = Levels[String.lower(level)]
    done = true
  else
    for k,v in pairs(Levels) do
      if level == Levels[k] then
        self.level = level
        done = true
        break
      end
    end
  end

  if done then
    for key, logger in pairs(self.loggers) do
      logger:setParentLevel(self.level)
    end
  end
end

function _Logger:getLevel()
  return self.level
end

function _Logger:log(level, s, ...)
  if type(level) ~= "table" or type(s) ~= "string" then
    return
  end

  for key, logger in pairs(self.loggers) do
    logger:log(1, level, s, ...)
  end
end

function _Logger:logn(n, level, s, ...)
  if type(level) ~= "table" or type(s) ~= "string" then
    return
  end

  for key, logger in pairs(self.loggers) do
    logger:log(n + 1, level, s, ...)
  end
end

for key,value in pairs(Levels) do
  _Logger[key] = function(self, ...)
    self:logn(1, Levels[key], ...)
  end
end

function _Logger:close()
  for i, logger in ipairs(self.loggers) do
    logger:close()
  end
end

local _loggers = {}

local Logger = Object:extend()

Logger.ERROR = Levels["error"]
Logger.WARN  = Levels["warn"]
Logger.INFO  = Levels["info"]
Logger.DEBUG = Levels["debug"]
Logger.TRACE = Levels["trace"]

function Logger:initialize(options)

  local configuration = Configuration:new(options)
  local json = configuration:read()

  if not json then
    error("error in json configuration file")
  end

  for key, value in pairs(json) do

    local opts = value
    if type(opts.name) ~= "string" then
      error("logger name: " .. Print.dump(opts.name) .. " is not a string")
    end

    _loggers[opts.name] = _Logger:new(opts)
  end
end

function Logger.getLogger(name)
  if not _loggers[name] then
    error("Logger \"" .. name .. "\" not initialized")
  end
  return _loggers[name]
end

function Logger.close()
  for key, value in pairs(_loggers) do
    _loggers[key]:close()
    _loggers[key] = nil
  end
end

return Logger
