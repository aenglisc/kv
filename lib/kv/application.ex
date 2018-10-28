defmodule Kv.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Kv.Worker.start_link(arg)
      # {Kv.Worker, arg},
    ]

    opts = [strategy: :one_for_one, name: Kv.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
