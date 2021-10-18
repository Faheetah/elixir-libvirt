defmodule Libvirt.Domain do
  @moduledoc false

  @enforce_keys [:name, :image_path]
  defstruct [:name, :uuid, :image_path, memory: 2048, vcpu: 2]

  def gen_xml(%__MODULE__{} = domain) do
  """
<domain type='kvm'>
  <name>#{domain.name}</name>
  <uuid>#{domain.uuid}</uuid>
  <memory unit='MiB'>#{domain.memory}</memory>
  <currentMemory unit='MiB'>#{domain.memory}</currentMemory>
  <vcpu placement='static'>#{domain.vcpu}</vcpu>
  <os>
    <type arch='x86_64'>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <vmport state='off'/>
  </features>
  <devices>
    <emulator>/usr/bin/kvm-spice</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='#{domain.image_path}'/>
      <target dev='hda' bus='ide'/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
  </devices>
</domain>
"""
  end

  def list_all(socket) do
    Libvirt.connect_list_all_domains(socket, %{"need_results" => 1, "flags" => 0})
  end

  def get_xml(socket, domain) do
    Libvirt.domain_get_xml_desc(socket, %{"dom" => domain, "flags" => 0})
  end

  def define(socket, xml) do
    Libvirt.domain_define_xml(socket, %{"xml" => xml})
  end

  def start(socket, domain) do
    Libvirt.domain_create(socket, %{"dom" => domain})
  end

  def stop(socket, domain) do
    Libvirt.domain_destroy(socket, %{"dom" => domain})
  end

  def undefine(socket, domain) do
    Libvirt.domain_undefine(socket, %{"dom" => domain})
  end

  def get_info(socket, domain) do
    Libvirt.domain_get_info(socket, %{"dom" => domain})
  end
end
