defmodule Kv.Storage.Logic do
  @moduledoc """
  Storage logic
  """

  @kv Application.get_env(:kv, :storage)
  @storage_file Application.get_env(:kv, :storage_file)

  def create(k, v, :infinity)
  when is_binary(k) and is_binary(v) do
    do_create({k, v, :infinity})
  end

  def create(k, v, ttl)
  when is_binary(k) and is_binary(v) and is_integer(ttl) do
    do_create({k, v, gen_ttl(ttl)})
  end

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

  def read(k) when is_binary(k) do
    now = :os.system_time(:millisecond)
    case :ets.lookup(@kv, k) do
      [{_k, v, ttl}] when ttl > now -> {:ok, v}
      _ -> {:error, :not_found}
    end
  end

  def read_ttl(k) when is_binary(k) do
    now = :os.system_time(:millisecond)
    case :ets.lookup(@kv, k) do
      [{_k, _v, :infinity}] -> {:ok, :infinity}
      [{_k, _v, ttl}] when ttl > now -> {:ok, now - ttl}
      _ -> {:error, :not_found}
    end
  end

  def update(k, v, ttl)
  when is_binary(k) and is_binary(v) and is_integer(ttl) do
    do_update({k, v, gen_ttl(ttl)})
  end

  def update(k, ttl, nil)
  when is_binary(k) and is_integer(ttl) do
    do_update({k, nil, ttl})
  end

  def update(k, :infinity, nil)
  when is_binary(k) do
    do_update({k, nil, :infinity})
  end

  def update(k, v, :infinity)
  when is_binary(k) and is_binary(v) do
    do_update({k, v, :infinity})
  end

  def update(k, v, nil)
  when is_binary(k) and is_binary(v) do
    do_update({k, v, nil})
  end

  def update(k, nil, ttl)
  when is_binary(k) and is_integer(ttl) do
    do_update({k, nil, gen_ttl(ttl)})
  end

  def update(k, nil, :infinity)
  when is_binary(k) do
    do_update({k, nil, :infinity})
  end

  defp do_update({k, v, ttl}) do
    now = :os.system_time(:millisecond)
    case :ets.lookup(@kv, k) do
      [] ->
        {:error, :not_found}

      [{_k, _v, old_ttl}] when old_ttl <= now ->
        {:error, :not_found}

      [{_k, old_v, _ttl}] when is_nil(v) ->
        :ets.insert(@kv, {k, old_v, ttl})
        {:ok, {k, old_v}}

      [{_k, _v, old_ttl}] when is_nil(ttl) ->
        :ets.insert(@kv, {k, v, old_ttl})
        {:ok, {k, v}}

      [{_k, _v, _ttl}] ->
        :ets.insert(@kv, {k, v, ttl})
        {:ok, {k, v}}
    end
  end

  def delete(k) when is_binary(k) do
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
