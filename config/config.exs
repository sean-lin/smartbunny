# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for third-
# party users, it should be done in your mix.exs file.

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

config :smart_bunny, [
  mode: :client,  # client | server
  tunnel: %{
    name: "tun0",
    ip: {10, 0, 0, 1},
    remote: {10, 0, 0, 2},
  },
  local: [
    %{ 
      interface: "eth0",
      port: 12306,
    }
  ],
  remote: %{
    ip: {172, 16, 101, 201},
    port: 12306,
  },
  cookie: "Hi, bunny!",
  http: [
    listen_ip: {127, 0, 0, 1},
    listen_port: 8080
  ],
]

config :logger, [
  compile_time_purge_level: :debug,
  level: :debug,
  utc_log: true,
  backends: [
    :console,
    {LoggerFileBackend, :error_file},
    {LoggerFileBackend, :debug_file},
    ]
]

config :logger, [
  error_file: [path: "log/gb_error.log", level: :error],
  debug_file: [path: "log/gb_debug.log", level: :debug],
]
