import Config

config :logger,
  backends: [:console]

config :libvirt, :rpc, backend: Libvirt.RPC.Backends.Shared

import_config "#{config_env()}.exs"
