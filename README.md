# metaluvit

Lua ([luvit](https://luvit.io/)) discord bot/relay.


### 1. Connections

- **Discord**: [Discordia](https://github.com/SinisterRectus/Discordia) library
 - **[IRC](https://github.com/radare/luvit-irc)**
   - **Purpose**: Relays messages from discord to IRC (not from ingame, those are in separate irc client inside each game server)
 - **Game server** WebSocket gameserver side [here](https://gitlab.com/metastruct/fast_addons/blob/master/lua/fast_addons/server/discord.lua#L27) (TODO: Move into github?)
    - **Purpose**: Chat Relay: ingame<->discord
 - **Web server**: list discord group emojis

### 2. Usage

Some commands:

 - Discord #xchat commands:
   - **!disable / !enable** Toggle relaying chat messages
 - IRC:
   - **.status** List servers 

### 3. Viewing metaluvit daemon output

You can view the daemon output through the [rocket2](https://metastruct.net/rocket2) web interface or standalone with [this link](https://g2cf.metastruct.net/rocket/?arg=showluvit).

This console can also be used for interactive purposes.

To manually restart luvit: run [gserv2 luvit_update](https://g2cf.metastruct.net/rocket/?arg=luvit_update)

#### 3.1. Hosting

Metaluvit is running on r8.metastruct.net (g2.metastruct.net) presently on a separate user account (metaluvit) for isolation.

In SSH (as srcds) you can use ```$ gserv2 showluvit``` to view the process output on srcds user account. In metaluvit you have to access the named pipe to view the output.

Daemon starts on server start automatically. Daemon uses the same "daemon" process that gserv srcds uses, which multiplexes the terminal to all connecting clients.

### 4. Committing

Each commit restarts daemon with updated code. There is no other interface presently for simplicity.

The commit webhook in this repo accesses nginx fastdl on meta2 which uses a very restricted sudo to execute an update command as the metaluvit user account, which does a git pull and kills the process.

### 5. Test environment setup

TODO, probably too hard. Test in production, since no revenue will be lost.

### Roadmap

 - TODO
 
### Credits
 - Check commit history
