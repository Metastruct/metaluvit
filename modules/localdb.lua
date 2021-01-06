local sql = require"sqlite3"
local conn = sql.open("../metaluvit.db")
local _M = {}
_M.conn = conn
conn:exec[[
CREATE TABLE IF NOT EXISTS kv (key text unique, value text)
]]
local get_statement = conn:prepare("SELECT value FROM kv WHERE key==?")

local function get(key)
	local t = get_statement:reset():bind(tostring(key)):step({})
	if not t then return end
	return t[1]
end

local UNSET = {}
_M.UNSET = UNSET
local unset_statement = conn:prepare("DELETE FROM kv WHERE key=?")

local function unset(key)
	unset_statement:reset():bind(tostring(key)):step({})

	return conn:exec[[SELECT changes()]][1][1] == 1
end

local set_statement = conn:prepare("REPLACE INTO kv (key, value) VALUES (?,?)")

local function set(key, value)
	if not value or value == _M.UNSET then
		return unset(key)
	else
		set_statement:reset():bind(tostring(key), tostring(value)):step({})

		return conn:exec[[SELECT changes()]][1][1] == 1
	end
end

_M.set = set
_M.get = get
_M.unset = unset

local last_test
function _M.assureWritable()
	local want = tostring(os.time())
	if last_test == want then return true end
	assert(_M.set("write_test_293823",want),"could not write to database")
	local want2 = _M.get("write_test_293823")
	assert(want2==want,("Database write failed: %q!=%q"):format(want,want2))
end

_M.kv = setmetatable({
	UNSET = _M.UNSET,
	set = set,
	get = get,
	unset = unset
}, {
	__index = function(_, k) return get(k) end,
	__newindex = function(_, k, v)
		assert(set(k, v))
	end
})

return _M
