defmodule Libvirt.Network do
  @moduledoc false

  def list_all(socket) do
    Libvirt.connect_list_all_networks(socket, %{"need_results" => 1, "flags" => 0})
  end

  def get_xml(socket, network) do
    Libvirt.network_get_xml_desc(socket, %{"net" => network, "flags" => 0})
  end

  def define(socket, xml) do
    Libvirt.network_define_xml(socket, %{"xml" => xml})
  end

  def undefine(socket, network) do
    Libvirt.network_undefine(socket, %{"net" => network})
  end
end
