defmodule Kv.Storage do
  @moduledoc """
  Storage API
  """

  alias Kv.Storage.Logic

  @doc """
  Create a key-value pair in the storage with an assigned ttl
  TTL is infinity by default
  """
  @spec create(binary(), binary(), integer() | :infinity) :: {:ok, {binary(), binary()}} | {:error, :already_exists}
  defdelegate create(key, value, ttl \\ :infinity), to: Logic

  @doc """
  Read a key-value pair in the storage
  """
  @spec read(binary()) :: {:ok, any()} | {:error, :not_found}
  defdelegate read(key), to: Logic

  @doc """
  Read the ttl of a key-value pair in the storage
  """
  @spec read_ttl(binary()) :: {:ok, integer() | :infinity} | {:error, :not_found}
  defdelegate read_ttl(key), to: Logic

  @doc """
  Update a key-value pair in the storage with an assigned ttl
  TTL is nil by default
  """
  @spec update(binary(), binary() | nil, integer() | nil | :infinity) :: {:ok, {binary(), binary()}} | {:error, :not_found}
  defdelegate update(key, value \\ nil, ttl \\ nil), to: Logic

  @doc """
  Delete a key-value pair in the storage
  """
  @spec delete(binary()) :: {:ok, :deleted} | {:error, :not_found}
  defdelegate delete(key), to: Logic

  @doc """
  Remove outdated entries and persist
  """
  @spec clean_ttl_and_persist() :: :ok
  defdelegate clean_ttl_and_persist, to: Logic
end
