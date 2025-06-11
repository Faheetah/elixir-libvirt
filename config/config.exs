import Config

config :logger,
  backends: [:console]

config :libvirt, :rpc, backend: Libvirt.Backends.Direct

import_config "#{config_env()}.exs"
