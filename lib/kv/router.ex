defmodule Kv.Router do
  @moduledoc """
  The router for the kev-value storage
  """
  import Plug.Conn
  use Plug.Router
  use Plug.Debugger
  require Logger
  alias Kv.Storage

  @index_resp """
  Usage:

  Create
  POST /data?k=<key>&v=<value>&ttl=<value>

  Read
  GET /data/<key>

  Update
  PUT /data?k=<key>&v=<value>&ttl=<value>

  Delete
  DELETE /data/<key>
  """

  plug(Plug.Logger, log: :debug)
  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, @index_resp)
  end

  # TODO: create
  post "/data" do
    with conn = fetch_query_params(conn),
         {:ok, ttl} <- validate_ttl("create", conn.params),
         %{"k" => key, "v" => value} = conn.params,
         {:ok, key_value} <- Storage.create(key, value, ttl)
    do
      send_resp(conn, 201, inspect key_value)
    else
      {:error, :invalid_ttl} ->
        send_resp(conn, 422, "invalid ttl")

      {:error, :invalid_value} ->
        send_resp(conn, 422, "invalid value")

      {:error, :already_exists} ->
        send_resp(conn, 422, "already exists")

      {:error, reason} ->
        send_resp(conn, 422, inspect reason)
    end
  end

  # read
  get "/data/:key" do
    case Storage.read(key) do
      {:ok, value} -> send_resp(conn, 200, "#{value}")
      {:error, :not_found} -> send_resp(conn, 404, "not found")
    end
  end

  # update
  put "/data" do
    with conn = fetch_query_params(conn),
         {:ok, ttl} <- validate_ttl("update", conn.params),
         %{"k" => key, "v" => value} = conn.params,
         {:ok, key_value} <- Storage.update(key, value, ttl)
    do
      send_resp(conn, 200, inspect key_value)
    else
      {:error, :invalid_ttl} ->
        send_resp(conn, 422, "invalid ttl")

      {:error, :invalid_value} ->
        send_resp(conn, 422, "invalid value")

      {:error, :already_exists} ->
        send_resp(conn, 422, "already exists")

      {:error, reason} ->
        send_resp(conn, 422, inspect reason)
    end
  end

  # delete
  delete "/data/:key" do
    case Storage.delete(key) do
      {:ok, :deleted} -> send_resp(conn, 200, "deleted")
      {:error, :not_found} -> send_resp(conn, 404, "not found")
    end
  end

  match _ do
    send_resp(conn, 404, "Are you lost?")
  end

  defp validate_ttl("update", %{"ttl" => "nil"}), do: {:ok, nil}
  defp validate_ttl(_method,  %{"ttl" => "infinity"}), do: {:ok, :infinity}
  defp validate_ttl(_method,  %{"ttl" => ttl}), do: parse_ttl(ttl)
  defp validate_ttl("create", _params), do: {:ok, :infinity}
  defp validate_ttl("update", _params), do: {:ok, nil}

  defp parse_ttl(ttl) do
    case Integer.parse(ttl) do
      {ttl, _} -> {:ok, ttl}
      _ -> {:error, :invalid_ttl}
    end
  end
end
