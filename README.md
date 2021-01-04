# metaluvit

Lua ([luvit](https://luvit.io/)) discord bot for ... things. 

Old relay bot can be found at https://github.com/Metastruct/metaluvit/tree/master-preneutering
New relay bot is in https://github.com/Metastruct/node-metaconcord

### 1. Connections

- **Discord**: [Discordia](https://github.com/SinisterRectus/Discordia) library
- **Web server**: None
 
### 2. Usage

None

### 3. Viewing metaluvit daemon output (on metastruct)

You can view the daemon output through the [rocket](https://metastruct.net/rocket2) web interface or directly with [this link](https://g2cf.metastruct.net/rocket/?arg=showluvit).

This console can also be used for interactive purposes.

To manually restart luvit: run [gserv luvit_update](https://g2cf.metastruct.net/rocket/?arg=luvit_update)

#### 3.1. Hosting

Metaluvit is running on r8.metastruct.net (g2.metastruct.net) presently on a separate user account (metaluvit) for isolation.

In SSH (as srcds) you can use ```$ gserv showluvit``` to view the process output on srcds user account. In metaluvit you have to access the named pipe to view the output.

Daemon starts on server start automatically. Daemon uses the same "daemon" process that gserv srcds uses, which multiplexes the terminal to all connecting clients.

### 4. Committing

Each commit restarts daemon with updated code. There is no other interface presently for simplicity.

The commit webhook in this repo accesses nginx fastdl on meta2 which uses a very restricted sudo to execute an update command as the metaluvit user account, which does a git pull and kills the process.

### 5. Test environment setup

Get luvit from https://luvit.io. Set up a custom test discord server and bot credentials and run main.lua.

### Roadmap

 - Minimal automation of things like server icon changes
 
### Credits

 - Check commit history
