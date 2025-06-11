defmodule Libvirt.Pool do
  @moduledoc false

  def list_all(socket) do
    Libvirt.connect_list_all_storage_pools(socket, %{"need_results" => 1, "flags" => 0})
  end

  def get_xml(socket, pool) do
    Libvirt.storage_pool_get_xml_desc(socket, %{"pool" => pool, "flags" => 0})
  end

  def get_by_name(socket, name) do
    Libvirt.storage_pool_lookup_by_name(socket, %{"name" => name})
  end

  def create(socket, %{"name" => name, "uuid" => uuid}, path, type \\ "dir") do
    xml = """
    <pool type='#{type}'>
      <name>#{name}</name>
      <uuid>#{uuid}</uuid>
      <target>
        <path>#{path}</path>
        <permissions>
          <mode>0755</mode>
          <owner>-1</owner>
          <group>-1</group>
        </permissions>
      </target>
    </pool>
    """

    {:ok, %{"remote_nonnull_storage_pool" => pool}} =
      Libvirt.storage_pool_define_xml(socket, %{"xml" => xml, "flags" => 0})

    Libvirt.storage_pool_build(socket, %{"pool" => pool, "flags" => 0})
    Libvirt.storage_pool_create(socket, %{"pool" => pool, "flags" => 0})
    pool
  end

  def destroy(socket, pool) do
    # should ensure all volumes are destroyed first, maybe throw error
    # and use destroy! to force wipe all volumes
    Libvirt.storage_pool_destroy(socket, %{"pool" => pool})
  end

  def undefine(socket, pool) do
    Libvirt.storage_pool_undefine(socket, %{"pool" => pool})
  end

  def delete(socket, pool) do
    Libvirt.storage_pool_delete(socket, %{"pool" => pool, "flags" => 0})
  end
end
