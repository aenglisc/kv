defmodule KvTest.Storage do
  use ExUnit.Case
  alias Kv.Storage

  @kv Application.get_env(:kv, :storage)
  @storage_file Application.get_env(:kv, :storage_file)

  describe "storage api" do
    test "create" do
      assert {:ok, {"a", "1"}} = Storage.create("a", "1")
      assert {:error, :already_exists} = Storage.create("a", "2")
      assert {:ok, {"b", "1"}} = Storage.create("b", "1", 10)
      Process.sleep(10)
      assert {:ok, {"b", "2"}} = Storage.create("b", "2")
    end

    test "read" do
      assert {:ok, {"c", "1"}} = Storage.create("c", "1", 10)
      assert {:ok, "1"} = Storage.read("c")
      Process.sleep(10)
      assert {:error, :not_found} = Storage.read("c")
    end

    test "read_ttl" do
      assert {:ok, {"d", "1"}} = Storage.create("d", "1", 10)
      assert {:ok, ttl} = Storage.read_ttl("d")
      assert ttl <= 10
      Process.sleep(10)
      assert {:error, :not_found} = Storage.read_ttl("d")
      assert {:ok, {"d", "1"}} = Storage.create("d", "1")
      assert {:ok, :infinity} = Storage.read_ttl("d")
    end

    test "update" do
      assert {:ok, {"e", "1"}} = Storage.create("e", "1")
      assert {:ok, :infinity} = Storage.read_ttl("e")
      assert {:ok, {"e", "2"}} = Storage.update("e", "2")
      assert {:ok, "2"} = Storage.read("e")
      assert {:ok, {"e", "2"}} = Storage.update("e", 10)
      Process.sleep(10)
      assert {:error, :not_found} = Storage.update("e", "1")
    end

    test "delete" do
      assert {:ok, {"f", "1"}} = Storage.create("f", "1")
      assert {:ok, :deleted} = Storage.delete("f")
      assert {:ok, {"f", "1"}} = Storage.create("f", "1", 10)
      Process.sleep(10)
      assert {:error, :not_found} = Storage.delete("f")
    end
  end

  describe "clean ttl and persist" do
    setup do
      on_exit fn ->
        File.rm @storage_file
      end
    end

    test "table is persisted, outdated values are removed" do
      Storage.create("ttl_test", "test", 1)
      Process.sleep(1)
      assert [{"ttl_test", "test", _}] = :ets.lookup(@kv, "ttl_test")
      assert :ok = Storage.clean_ttl_and_persist
      assert [] = :ets.lookup(@kv, "ttl_test")
      assert File.exists?(@storage_file)
    end
  end
end
