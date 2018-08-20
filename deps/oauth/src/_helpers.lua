local string = require('string')
local math = require('math')
local table = require('table')
local crypto = require('tls/lcrypto')
local os = require('os')
local qs = require('querystring')

local exports = {}

-- generates a unix timestamp
function exports.generateTimestamp ()
  return tostring(os.time())
end

-- encoding following OAuth's specific semantics
function exports.oauthEncode (val)
  return val:gsub('[^-._~a-zA-Z0-9]', function (letter)
    return string.format("%%%02x", letter:byte()):upper()
  end)
end

-- generates a nonce (number used once)
local NONCE_CHARS = {
  'a','b','c','d','e','f','g','h','i','j','k','l','m','n',
  'o','p','q','r','s','t','u','v','w','x','y','z','A','B',
  'C','D','E','F','G','H','I','J','K','L','M','N','O','P',
  'Q','R','S','T','U','V','W','X','Y','Z','0','1','2','3',
  '4','5','6','7','8','9'
}
function exports.generateNonce (nonceSize)
  local result = {}

  local i = 1
  while i < nonceSize do
    local char_pos = math.floor(math.random() * #NONCE_CHARS)
    result[i] = NONCE_CHARS[char_pos]
    i = i + 1
  end

  return table.concat(result, '')
end

-- encode string into base64
local base64_table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
function exports.base64Encode (data)
  return ((string.gsub(data, '.', function(x)
    local r, b = '', string.byte(x)

    for i = 8, 1, -1 do
      r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
    end

    return r
  end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    if #x < 6 then
      return ''
    end

    local c = 0
    for i = 1, 6 do
      c = c + (string.sub(x, i, i) == '1' and 2 ^ (6 - i) or 0)
    end

    return string.sub(base64_table, c + 1, c + 1)
  end) .. ({
    '',
    '==',
    '='
  })[#data % 3 + 1])
end

-- some hosts *cough* google appear to close the connection early / send no content-length header
-- allow this behaviour
function exports.isAnEarlyCloseHost (hostName)
  return hostName and hostName:match('.*google(apis)?.com$')
end

-- querystring stringify
exports.stringify = qs.stringify

return exports
