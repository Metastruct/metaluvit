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

local OS = require("os")
local Clock = require("clocktime")
local String = require("string")
local Path   = require("path")

function __FILE__(n) return debug.getinfo(n + 2, 'S').source end
function __LINE__(n) return debug.getinfo(n + 2, 'l').currentline end
function __FUNC_NAME__(n) return debug.getinfo(n + 2, 'n').name end

local _Utils = {}

local Levels = {
  ["error"] = {value = 0, name = "ERROR"},
  ["warn"]  = {value = 1, name = "WARN"},
  ["info"]  = {value = 2, name = "INFO"},
  ["debug"] = {value = 3, name = "DEBUG"},
  ["trace"] = {value = 4, name = "TRACE"}
}
_Utils.Levels = Levels

function _Utils.formatDate(dateformat)
  if dateformat then
    return OS.date(dateformat)
  else
    local s, ms, ns = Clock.time({ msec = true })
    return OS.date("![%Y-%m-%d][%H:%M:%S." .. String.format("%03.0f", ms) .. "]", s)
  end
end

function _Utils.formatLevel(level)
  local str = {}
  table.insert(str, "[")
  table.insert(str, String.format("%-5s", level.name))
  table.insert(str, "]")
  return table.concat(str, "")
end

function _Utils.formatFuncName(n)
  local func_name = {}
  table.insert(func_name, "[")
  table.insert(func_name, Path.basename(__FILE__(n + 1)))
  table.insert(func_name, "::")
  table.insert(func_name, __FUNC_NAME__(n + 1))
  table.insert(func_name, ":")
  table.insert(func_name, __LINE__(n + 1))
  table.insert(func_name, "]")
  return table.concat(func_name, "")
end

function _Utils.finalStringWithoutDate(level, s, ...)
  local str = {}
  table.insert(str, _Utils.formatLevel(level))
  table.insert(str, " ")
  local text = s
  local arg = ...
  if arg then
    text = String.format(s, ...)
  end
  table.insert(str, text)
  return table.concat(str, "")
end

function _Utils.finalString(n, dateformat, level, s, ...)
  local str = {}
  table.insert(str, _Utils.formatDate(dateformat))
  table.insert(str, _Utils.formatLevel(level))
  table.insert(str, " ")
  local text = s
  local arg = ...
  if arg then
    text = String.format(s, ...)
  end
  table.insert(str, text)
  return table.concat(str, "")
end

function _Utils.finalStringWithFuncInfo(n, dateformat, level, s, ...)
  local str = {}
  table.insert(str, _Utils.formatDate(dateformat))
  table.insert(str, _Utils.formatLevel(level))
  table.insert(str, _Utils.formatFuncName(n + 1))
  table.insert(str, " ")
  local text = s
  local arg = ...
  if arg then
    text = String.format(s, ...)
  end
  table.insert(str, text)
  return table.concat(str, "")
end

return _Utils
