defmodule KvTest do
  use ExUnit.Case
  use Plug.Test
  alias Kv.Router

  @storage_file Application.get_env(:kv, :storage_file)
  @opts Router.init([])
  @query_type "application/x-www-form-urlencoded"

  describe "http api" do
    test "/" do
      conn = conn(:get, "/", "")
             |> Router.call(@opts)

      assert conn.status == 200
      assert conn.resp_body =~ "Usage"
    end

    test "not found" do
      conn = conn(:get, "/not_found", "")
             |> Router.call(@opts)

      assert conn.status == 404
      assert conn.resp_body =~ "Are you lost?"
    end

    test "create" do
      conn = conn(:post, "/data", %{k: "create", v: "create"})
             |> put_req_header("content-type", @query_type)
             |> Router.call(@opts)

      assert conn.status == 201
      assert conn.resp_body =~ "{\"create\", \"create\"}"

      conn = conn(:post, "/data", %{k: "create", v: "create", ttl: "error"})
             |> put_req_header("content-type", @query_type)
             |> Router.call(@opts)

      assert conn.status == 422
      assert conn.resp_body =~ "invalid ttl"

      conn = conn(:post, "/data", %{k: "create", v: "create"})
             |> put_req_header("content-type", @query_type)
             |> Router.call(@opts)

      assert conn.status == 422
      assert conn.resp_body =~ "already exists"
    end

    test "read" do
      conn = conn(:post, "/data", %{k: "read", v: "read"})
             |> put_req_header("content-type", @query_type)
             |> Router.call(@opts)

      assert conn.status == 201
      assert conn.resp_body =~ "{\"read\", \"read\"}"

      conn = conn(:post, "/data", %{k: "read1", v: "read1", ttl: "10"})
             |> put_req_header("content-type", @query_type)
             |> Router.call(@opts)

      assert conn.status == 201
      assert conn.resp_body =~ "{\"read1\", \"read1\"}"

      conn = conn(:get, "/data/read", "")
             |> Router.call(@opts)

      assert conn.status == 200
      assert conn.resp_body =~ "read"

      conn = conn(:get, "/data/nope", "")
             |> Router.call(@opts)

      assert conn.status == 404
      assert conn.resp_body =~ "not found"

      Process.sleep(10)

      conn = conn(:get, "/data/read1", "")
             |> Router.call(@opts)

      assert conn.status == 404
      assert conn.resp_body =~ "not found"
    end

    test "update" do
      conn = conn(:post, "/data", %{k: "update", v: "update"})
             |> put_req_header("content-type", @query_type)
             |> Router.call(@opts)

      assert conn.status == 201
      assert conn.resp_body =~ "{\"update\", \"update\"}"

      conn = conn(:get, "/data/update", "")
             |> Router.call(@opts)

      assert conn.status == 200
      assert conn.resp_body =~ "update"

      conn = conn(:put, "/data", %{k: "update", v: "updated"})
             |> put_req_header("content-type", @query_type)
             |> Router.call(@opts)

      assert conn.status == 200
      assert conn.resp_body =~ "{\"update\", \"updated\"}"

      conn = conn(:get, "/data/update", "") |> Router.call(@opts)

      assert conn.status == 200
      assert conn.resp_body =~ "updated"

      conn = conn(:put, "/data", %{k: "update", v: "updated", ttl: "10"})
             |> put_req_header("content-type", @query_type)
             |> Router.call(@opts)

      assert conn.status == 200
      assert conn.resp_body =~ "{\"update\", \"updated\"}"

      Process.sleep(10)

      conn = conn(:get, "/data/update", "")
             |> Router.call(@opts)

      assert conn.status == 404
      assert conn.resp_body =~ "not found"
    end

    test "delete" do
      conn = conn(:post, "/data", %{k: "delete", v: "delete"})
             |> put_req_header("content-type", @query_type)
             |> Router.call(@opts)

      assert conn.status == 201
      assert conn.resp_body =~ "{\"delete\", \"delete\"}"

      conn = conn(:post, "/data", %{k: "delete1", v: "delete1", ttl: "10"})
             |> put_req_header("content-type", @query_type)
             |> Router.call(@opts)

      assert conn.status == 201
      assert conn.resp_body =~ "{\"delete1\", \"delete1\"}"

      conn = conn(:get, "/data/delete", "")
             |> Router.call(@opts)

      assert conn.status == 200
      assert conn.resp_body =~ "delete"

      conn = conn(:delete, "/data/delete", "")
             |> Router.call(@opts)

      assert conn.status == 200
      assert conn.resp_body =~ "deleted"

      conn = conn(:get, "/data/delete", "")
             |> Router.call(@opts)

      assert conn.status == 404
      assert conn.resp_body =~ "not found"

      Process.sleep(10)

      conn = conn(:delete, "/data/delete1", "")
             |> Router.call(@opts)

      assert conn.status == 404
      assert conn.resp_body =~ "not found"
    end
  end
end
