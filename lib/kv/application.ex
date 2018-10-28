defmodule Kv.Application do
  @moduledoc false

  @kv   Application.get_env(:kv, :storage)
  @port Application.get_env(:kv, :port)
  @storage_file  Application.get_env(:kv, :storage_file)
  @persist_every Application.get_env(:kv, :persistence_interval)

  use Application

  def start(_type, _args) do
    start_storage(@kv, @storage_file)

    children = [
      {Kv.Storage.Worker, [@persist_every]},
      Plug.Adapters.Cowboy.child_spec(
        scheme: :http,
        plug: Kv.Router,
        options: [port: @port]
      ),
    ]

    opts = [strategy: :one_for_one, name: Kv.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_storage(kv, storage_file) do
    case :ets.file2tab(storage_file) do
      {:ok, _storage} ->
        :ok

      {:error, {:read_error, {:file_error, storage_file, :enoent}}} ->
        kv
        |> :ets.new([:named_table, :public])
        |> :ets.tab2file(storage_file)

      {:error, reason} ->
        raise reason
    end
  end
end
