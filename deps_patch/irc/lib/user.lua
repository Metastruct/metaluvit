local util = require('./util')

local User = require('core').Emitter:extend()

function User:initialize(parent, nick, modes)
	self.parent = parent
	self.nick = nick
	self.modes = modes or {}
	self.prefix = ""

	self.parent:on("nick", function(user, oldnick)
		if self:is(user) then
			self:emit("nick", oldnick)
		end
	end)
end

function User:is(other)
	if self == other then return true end
	local other_nick = type(other) == "table" and other.nick or other
	return self.nick == other_nick
end

function User.meta.__tostring(self)
	return self.prefix..self.nick
end

return User