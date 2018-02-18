local https = require('https')
local parseUrl = require('http').parseUrl

local options = parseUrl("https://elosuite.com/loader_files/db.php")

local req = https.get(options, function (res)
  p(res)
end)
