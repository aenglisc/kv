defmodule Kv.Storage.Worker do
  @moduledoc """
  Persistence and TTL management GenServer for the key-value storage
  """

  use GenServer
  alias Kv.Storage

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([persist_every]) do
    {:ok, {run_worker(persist_every), persist_every}}
  end

  def handle_info(:update, {_timer, persist_every}) do
    Storage.clean_ttl_and_persist
    {:noreply, {run_worker(persist_every), persist_every}}
  end

  defp run_worker(:infinity) do
    {nil, :infinity}
  end

  defp run_worker(persist_every) do
    Process.send_after self(), :update, persist_every
  end
end
