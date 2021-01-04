--[[
lit-meta
name = "metaluvit"
version = "0.0.2"
dependencies = {}
description = "Metastruct Luvit Based Daemon"
tags = { "metastruct", "chat", "luvit" }
license = "MIT"
author = { name = "metastruct", email = "metastruct@metastruct.uk.to" }
homepage = "https://metastruct.net/"
]]


local log = require'modules/logsys'
log:debug"preloading"
for _,file in pairs(fs.readdirSync("preload/")) do
	if file:find("%.lua$") then
		dofile(file)
	end
end

log:debug"Running autorun..."
RunAutorun()
log:debug"Finished loading"

log:debug"Starting repl..."
require("modules/repl")