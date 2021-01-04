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

local ffi = require("ffi")

ffi.cdef[[
  typedef int clockid_t;
  struct timespec {
    long int tv_sec;
    long int tv_nsec;
  };
  int clock_gettime(clockid_t clock_id, struct timespec *);
]]

local SYSTEM_CLOCK_ID = {
  CLOCK_REALTIME = 0,
  CLOCK_MONOTONIC = 1
}

function time(options)

  local timespec = ffi.new("struct timespec")

  ffi.C.clock_gettime(SYSTEM_CLOCK_ID.CLOCK_REALTIME, timespec)

  local time = {}

  table.insert(time, tonumber(timespec.tv_sec))

  if options and options.msec then
    local msec, dec = math.modf(tonumber(timespec.tv_nsec) / 10e5)
    table.insert(time, msec)
  end

  table.insert(time, tonumber(timespec.tv_nsec))

  return unpack(time)
end

exports.time = time
