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
    Libvirt.RPC.Call.storage_vol_download(socket, %{"vol" => volume, "offset" => 0, "length" => 0, "flags" => 0})
  end

  def download(socket, volume, dest) do
    if File.exists?(dest) do
      {:error, "file exists"}
    else
      Libvirt.RPC.Call.storage_vol_download(socket, %{"vol" => volume, "offset" => 0, "length" => 0, "flags" => 0})
    end
  end

  # need to implement feeding the streem into the upload
  def upload!(socket, volume, dest) do
    stream = File.open(dest)
    Libvirt.RPC.Call.storage_vol_download(socket, %{"vol" => volume, "offset" => 0, "length" => 0, "flags" => 0})
  end

  def uplaod(socket, volume, dest) do
    if File.exists?(dest) do
      {:error, "file exists"}
    else
      Libvirt.RPC.Call.storage_vol_download(socket, %{"vol" => volume, "offset" => 0, "length" => 0, "flags" => 0})
    end
  end
end
