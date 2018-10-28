use Mix.Config

config :kv, storage: :storage
config :kv, port: 7777

import_config "#{Mix.env()}.exs"
