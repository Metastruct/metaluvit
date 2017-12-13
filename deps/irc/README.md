luvit-irc [![Build Status](https://travis-ci.org/squeek502/luvit-irc.svg?branch=master)](https://travis-ci.org/squeek502/luvit-irc)
=========
IRC client module for [luvit](https://luvit.io)

Documentation
-------------
See test.lua for more information

TODO
----
* Add support for SSL

Example
-------
```lua
local server = "irc.server.address"
local IRC = require "luvit-irc"
local c = IRC:new(server, "botnick")
c:connect()
c:on ("connect", function (welcomemsg, server, nick)
	c:say ("yournick", "hello world")
	c:disconnect ()
end)
c:on ("disconnect", function (disconnectmsg)
	process.exit (0)
end)
```

Running The Tests
-----------------

With luvit: `luvit ./tests`

With lit/luvi: `luvi tests .`

To only run a specific test (e.g. 'test-message.lua'): `luvit ./tests message` or `luvi tests . -- message`
