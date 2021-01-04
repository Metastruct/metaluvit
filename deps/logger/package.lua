return {
  name = "gsick/logger",
  version = "0.1.6",
  description = "Logger for Luvit",
  tags = {
    "logger", "log", "logging",
    "file", "redis", "syslog"
  },
  author = {
    name = "Gamaliel Sick"
  },
  homepage = "https://github.com/gsick/lit-logger",
  dependencies = {
    "gsick/clocktime@1.0.0",
    "gsick/redis@0.0.1"
  },
  files = {
    "*.lua",
    "libs/*.lua",
    "!tests",
    "!examples"
  }
}
