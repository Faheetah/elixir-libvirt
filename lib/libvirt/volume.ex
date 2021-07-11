defmodule Libvirt.Volume do
  @moduledoc false

  def list_all(socket, pool) do
    Libvirt.RPC.Call.storage_pool_list_all_volumes(socket, %{"pool" => pool, "need_results" => 1, "flags" => 0})
  end

  def lookup_by_key(socket, pool, key) do
    {:ok, %{"remote_nonnull_storage_vol" => vol}} = Libvirt.RPC.Call.storage_vol_lookup_by_key(socket, %{"pool" => pool, "key" => key})
    vol
  end

  def lookup_by_name(socket, pool, name) do
    {:ok, %{"remote_nonnull_storage_vol" => vol}} = Libvirt.RPC.Call.storage_vol_lookup_by_name(socket, %{"pool" => pool, "name" => name})
    {:ok, vol}
  end

  def lookup_by_path(socket, path) do
    {:ok, %{"remote_nonnull_storage_vol" => vol}} = Libvirt.RPC.Call.storage_vol_lookup_by_path(socket, %{"path" => path})
    {:ok, vol}
  end

  def get_info(socket, vol) do
    Libvirt.RPC.Call.storage_vol_get_info(socket, %{"vol" => vol})
  end

  def download!(socket, volume, dest) do
    File.rm(dest)
    download(socket, volume, dest)
  end

  def download(socket, volume, dest) do
    false = File.exists?(dest)
    Libvirt.RPC.Call.storage_vol_download(socket, %{"vol" => volume, "offset" => 0, "length" => 0, "flags" => 0})
    get_data(dest)
  end

  def get_data(dest) do
    receive do
      {_, nil} -> :ok
      {_, payload} ->
        File.write(dest, payload, [:append])
        get_data(dest)
    end
  end
end
