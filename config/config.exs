use Mix.Config

config :kv, storage: :storage
config :kv, storage_file: 'storage.tab'
config :kv, persistence_interval: 1000
config :kv, port: 7777

import_config "#{Mix.env()}.exs"
