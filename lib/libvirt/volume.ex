defmodule Libvirt.Volume do
  @moduledoc false

  @enforce_keys [:name, :pool, :path]
  defstruct [:name, :pool, :capacity, :path, mode: "0600", unit: "G"]

  def list_all(socket, pool) do
    Libvirt.storage_pool_list_all_volumes(socket, %{
      "pool" => pool,
      "need_results" => 1,
      "flags" => 0
    })
  end

  def lookup_by_key(socket, pool, key) do
    {:ok, %{"remote_nonnull_storage_vol" => vol}} =
      Libvirt.storage_vol_lookup_by_key(socket, %{"pool" => pool, "key" => key})

    vol
  end

  def lookup_by_name(socket, pool, name) do
    Libvirt.storage_vol_lookup_by_name(socket, %{"pool" => pool, "name" => name})
  end

  def lookup_by_path(socket, path) do
    {:ok, %{"remote_nonnull_storage_vol" => vol}} =
      Libvirt.storage_vol_lookup_by_path(socket, %{"path" => path})

    {:ok, vol}
  end

  def get_info(socket, vol) do
    Libvirt.storage_vol_get_info(socket, %{"vol" => vol})
  end

  def download(socket, volume) do
    Libvirt.storage_vol_download(socket, %{
      "vol" => volume,
      "offset" => 0,
      "length" => 0,
      "flags" => 0
    })
  end

  def download(socket, volume, file: file) when is_binary(file) do
    if File.exists?(file) do
      {:error, "file exists"}
    else
      download(socket, volume)
      |> Stream.into(File.stream!(file))
      |> Stream.run()

      :ok
    end
  end

  def create(socket, %__MODULE__{} = volume) do
    xml = """
    <volume>
      <name>#{volume.name}</name>
      <allocation>0</allocation>
      <capacity unit="#{volume.unit}">#{volume.capacity}</capacity>
      <target>
        <path>#{volume.path}</path>
        <permissions>
          <mode>#{volume.mode}</mode>
        </permissions>
      </target>
    </volume>
    """

    {:ok, %{"remote_nonnull_storage_pool" => pool}} =
      Libvirt.Pool.get_by_name(socket, volume.pool)

    Libvirt.storage_vol_create_xml(socket, %{"pool" => pool, "xml" => xml, "flags" => 0})
  end

  def delete(socket, volume) do
    Libvirt.storage_vol_delete(socket, %{"vol" => volume, "flags" => 0})
  end

  def upload(socket, %__MODULE__{} = volume, file: file) do
    stream = File.stream!(file, [], 262_148)
    upload(socket, volume, stream)
  end

  def upload(socket, %__MODULE__{capacity: capacity} = volume, stream)
  when not is_nil(capacity) do
    vol_data = %{"key" => volume.path, "name" => volume.name, "pool" => volume.pool}

    Libvirt.storage_vol_upload(
      socket,
      %{"vol" => vol_data, "offset" => 0, "length" => 0, "flags" => 0},
      stream
    )
  end
end
