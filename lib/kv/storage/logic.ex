defmodule Kv.Storage.Logic do
  @moduledoc """
  Storage logic
  """

  @kv Application.get_env(:kv, :storage)
  @storage_file Application.get_env(:kv, :storage_file)

  def create(k, v, ttl) when is_integer(ttl), do: do_create({k, v, gen_ttl(ttl)})
  def create(k, v, :infinity), do: do_create({k, v, :infinity})

  defp do_create({k, v, _ttl} = term) do
    now = :os.system_time(:millisecond)
    case :ets.lookup(@kv, k) do
      [] ->
        :ets.insert(@kv, term)
        {:ok, {k, v}}

      [{_k, _v, :infinity}] ->
        {:error, :already_exists}

      [{_k, _v, old_ttl}] when old_ttl > now ->
        {:error, :already_exists}

      [{_k, _v, _ttl}] ->
        :ets.insert(@kv, term)
        {:ok, {k, v}}
    end
  end

  def read(k) do
    now = :os.system_time(:millisecond)
    case :ets.lookup(@kv, k) do
      [{_k, v, ttl}] when ttl > now -> {:ok, v}
      _ -> {:error, :not_found}
    end
  end

  def read_ttl(k) do
    now = :os.system_time(:millisecond)
    case :ets.lookup(@kv, k) do
      [{_k, _v, :infinity}] -> {:ok, :infinity}
      [{_k, _v, ttl}] when ttl > now -> {:ok, now - ttl}
      _ -> {:error, :not_found}
    end
  end

  def update(k, v, ttl) when is_integer(ttl), do: do_update({k, v, gen_ttl(ttl)})
  def update(k, v, :infinity), do: do_update({k, v, :infinity})
  def update(k, v, nil),       do: do_update({k, v, nil})

  defp do_update({k, v, ttl}) do
    now = :os.system_time(:millisecond)
    case :ets.lookup(@kv, k) do
      [] ->
        {:error, :not_found}

      [{_k, _v, old_ttl}] when old_ttl <= now ->
        {:error, :not_found}

      [{_k, _v, old_ttl}] when is_nil(ttl) ->
        :ets.insert(@kv, {k, v, old_ttl})
        {:ok, {k, v}}

      [{_k, _v, _ttl}] ->
        :ets.insert(@kv, {k, v, ttl})
        {:ok, {k, v}}
    end
  end

  def delete(k) do
    now = :os.system_time(:millisecond)
    case :ets.lookup(@kv, k) do
      [{_k, _v, ttl}] when ttl > now ->
        :ets.delete(@kv, k)
        {:ok, :deleted}

      _ ->
        {:error, :not_found}
    end
  end

  def clean_ttl_and_persist do
    :ets.select_delete(@kv, cleaner())
    :ets.tab2file(@kv, @storage_file)
  end

  defp cleaner do
    now = :os.system_time(:millisecond)
    [{{:_, :_, :"$1"}, [{:"=<", :"$1", now}], [true]}]
  end

  defp gen_ttl(ms), do: :os.system_time(:millisecond) + ms
end
