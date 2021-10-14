import Config

config :logger,
  backends: [:console]

import_config "#{config_env()}.exs"
