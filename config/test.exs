use Mix.Config

config :kv, storage: :test
config :kv, storage_file: 'test.tab'
config :kv, persistence_interval: :infinity
config :kv, port: 7778
