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

--package.path=package.path..';./?.lua'

-- https://github.com/luvit/luvit/blob/master/deps/require.lua
_G.require=require
_G.require_lua=require

print("package.path=",package.path)
local log = require'modules/logsys'
local fs = require'fs'

print""
log:debug"Running preload scripts..."
for _,file in pairs(fs.readdirSync("preload/")) do
	if file:find("%.lua$") then
		dofile("preload/"..file)
	end
end

print""
log:debug"Running autorun scripts..."
RunAutorun()
