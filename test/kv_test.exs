defmodule KvTest do
  use ExUnit.Case

  @port Application.get_env(:kv, :port)
  @storage_file Application.get_env(:kv, :storage_file)
  @uri "localhost:#{@port}"

  setup do
    on_exit fn ->
      File.rm @storage_file
    end
  end

  describe "http api" do
    test "/" do
      assert "Usage:" <> _ = curl("GET", "/")
    end

    test "not found" do
      assert "Are you lost?" = curl("GET", "/not_found")
    end

    test "create" do
      assert "{\"create\", \"create\"}" = curl("POST", "/data", "?k=create&v=create")
      assert "invalid ttl" = curl("POST", "/data", "?k=create&v=create&ttl=error")
      assert "already exists" = curl("POST", "/data", "?k=create&v=create")
    end

    test "read" do
      assert "{\"read\", \"read\"}" = curl("POST", "/data", "?k=read&v=read")
      assert "{\"read1\", \"read1\"}" = curl("POST", "/data", "?k=read1&v=read1&ttl=10")
      assert "read" = curl("GET", "/data/read")
      assert "not found" = curl("GET", "/data/nope")
      Process.sleep(10)
      assert "not found" = curl("GET", "/data/read1")
    end

    test "update" do
      assert "{\"update\", \"update\"}" = curl("POST", "/data", "?k=update&v=update")
      assert "update" = curl("GET", "/data/update")
      assert "{\"update\", \"updated\"}" = curl("PUT", "/data", "?k=update&v=updated")
      assert "updated" = curl("GET", "/data/update")
      assert "{\"update\", \"updated\"}" = curl("PUT", "/data", "?k=update&v=updated&ttl=10")
      Process.sleep(10)
      assert "not found" = curl("GET", "/data/update")
    end

    test "delete" do
      assert "{\"delete\", \"delete\"}" = curl("POST", "/data", "?k=delete&v=delete")
      assert "{\"delete1\", \"delete1\"}" = curl("POST", "/data", "?k=delete1&v=delete1&ttl=10")
      assert "delete" = curl("GET", "/data/delete")
      assert "deleted" = curl("DELETE", "/data/delete")
      assert "not found" = curl("GET", "/data/delete")
      Process.sleep(10)
      assert "not found" = curl("GET", "/data/delete1")
    end
  end

  defp curl(method, route, query \\ "") do
    uri = @uri <> route <> query
    {res, _} = System.cmd("curl", ["-s", "-X", method, uri])
    res
  end
end
