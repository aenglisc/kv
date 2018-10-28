defmodule KvTest do
  use ExUnit.Case

  @port Application.get_env(:kv, :port)
  @storage_file Application.get_env(:kv, :storage_file)

  setup do
    on_exit fn ->
      File.rm @storage_file
    end
  end

  describe "http api" do
    test "/" do
      assert {"Usage:" <> _, _} = System.cmd("curl", ["-s", "localhost:#{@port}"])
    end

    test "not found" do
      assert {"Are you lost?", _} = System.cmd("curl", ["-s", "localhost:#{@port}/not_found"])
    end

    test "create" do
      assert {"{\"create\", \"create\"}", _} = System.cmd("curl", ["-s", "-X", "POST", "localhost:#{@port}/data?k=create&v=create"])
      assert {"invalid ttl", _} = System.cmd("curl", ["-s", "-X", "POST", "localhost:#{@port}/data?k=create1&v=create1&ttl=error"])
      assert {"already exists", _} = System.cmd("curl", ["-s", "-X", "POST", "localhost:#{@port}/data?k=create&v=create"])
    end

    test "read" do
      assert {"{\"read\", \"read\"}", _} = System.cmd("curl", ["-s", "-X", "POST", "localhost:#{@port}/data?k=read&v=read"])
      assert {"{\"read1\", \"read1\"}", _} = System.cmd("curl", ["-s", "-X", "POST", "localhost:#{@port}/data?k=read1&v=read1&ttl=10"])
      assert {"read", _} = System.cmd("curl", ["-s", "-X", "GET", "localhost:#{@port}/data/read"])
      assert {"not found", _} = System.cmd("curl", ["-s", "-X", "GET", "localhost:#{@port}/data/nope"])
      Process.sleep(10)
      assert {"not found", _} = System.cmd("curl", ["-s", "-X", "GET", "localhost:#{@port}/data/read1"])
    end

    test "update" do
      assert {"{\"update\", \"update\"}", _} = System.cmd("curl", ["-s", "-X", "POST", "localhost:#{@port}/data?k=update&v=update"])
      assert {"update", _} = System.cmd("curl", ["-s", "-X", "GET", "localhost:#{@port}/data/update"])
      assert {"{\"update\", \"updated\"}", _} = System.cmd("curl", ["-s", "-X", "PUT", "localhost:#{@port}/data?k=update&v=updated"])
      assert {"updated", _} = System.cmd("curl", ["-s", "-X", "GET", "localhost:#{@port}/data/update"])
      assert {"{\"update\", \"updated\"}", _} = System.cmd("curl", ["-s", "-X", "PUT", "localhost:#{@port}/data?k=update&v=updated&ttl=10"])
      Process.sleep(10)
      assert {"not found", _} = System.cmd("curl", ["-s", "-X", "GET", "localhost:#{@port}/data/update"])
    end

    test "delete" do
      assert {"{\"delete\", \"delete\"}", _} = System.cmd("curl", ["-s", "-X", "POST", "localhost:#{@port}/data?k=delete&v=delete"])
      assert {"{\"delete1\", \"delete1\"}", _} = System.cmd("curl", ["-s", "-X", "POST", "localhost:#{@port}/data?k=delete1&v=delete1&ttl=10"])
      assert {"delete", _} = System.cmd("curl", ["-s", "-X", "GET", "localhost:#{@port}/data/delete"])
      assert {"deleted", _} = System.cmd("curl", ["-s", "-X", "DELETE", "localhost:#{@port}/data/delete"])
      assert {"not found", _} = System.cmd("curl", ["-s", "-X", "DELETE", "localhost:#{@port}/data/delete"])
      Process.sleep(10)
      assert {"not found", _} = System.cmd("curl", ["-s", "-X", "DELETE", "localhost:#{@port}/data/delete1"])
    end
  end
end
