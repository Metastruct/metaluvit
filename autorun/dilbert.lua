local db		= require'modules/localdb'
local log 		= require"modules/logsys"
local hook 		= require"modules/hook"

local timer 	= require"timer"
local fs 		= require"fs"
local config 	= require'config'
local http = require("coro-http")

local last_posted_url = db.get("dilbert-last")
db.assureWritable()

local function yesterdayDilbertURL()
	local datefmt=db.conn:exec"select strftime('%Y-%m-%d','now','-1 day')"[1][1]
	return "https://dilbert.com/strip/"..datefmt
end

local function isDilbert(url)
	local res,body = http.request("GET", url)
	if not res or res.code~=200 then
		return nil,res.code,res
	end
	return body,res
end

local checking
function startCheckDilbert()
	if checking then 
		log:debug("dilbert check overlapping!?")
		return 
	end
	coroutine.wrap(function()
		checking=true
		local url = yesterdayDilbertURL()
		if url == last_posted_url then
			log:debug("dilbert already posted: "..tostring(url))
			checking=false
			return
		end
		
		if not isDilbert(url) then
			log:info("no dilbert in "..url)
			checking=false
			return
		end
		checking=false
		
		
		log:debug("Posting dilbert: "..url)
		
		assert(db.set("dilbert-last",url))
		last_posted_url = url
		assert(last_posted_url == db.get("dilbert-last"))
			
		hook.run("onDilbert",url)
	end)()
end

			
startCheckDilbert()
timer.setInterval(2.12345*60*60*1000, function()
	startCheckDilbert()
end)


do 
	local discord 	= require'modules/discord'
	hook.add("onDilbert","dilbertEmitter",function(url)
		local channel = config.dilbert_channel or "541968605269458967"
		discord.client:getChannel(channel):send(url)
	end)
end
