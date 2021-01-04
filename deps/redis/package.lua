return {
  name = "gsick/redis",
  version = "0.0.1",
  description = "Redis Luvit",
  tags = {
    "redis", "hiredis"
  },
  author = {
    name = "Tadeusz Wójcik"
  },
  contributors = {
    "Gamaliel Sick"
  },
  homepage = "https://github.com/gsick/lit-redis",
  files = {
    "*.lua",
    "libs/$OS-$ARCH/*",
    "libs/*.lua",
    "!src",
    "!tests",
    "!examples"
  }
}
