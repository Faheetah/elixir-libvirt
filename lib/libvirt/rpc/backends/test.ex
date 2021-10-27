defmodule Libvirt.RPC.Backends.Test do
  def connect!(host) do
    {:ok, socket} = connect(host)
    socket
  end

  def connect(host) do
    Libvirt.RPC.Backends.Direct.connect(host, "test:///default", 57087)
  end

  defdelegate send(socket, packet, type), to: Libvirt.RPC.Backends.Direct
  defdelegate send(socket, packet, type, stream), to: Libvirt.RPC.Backends.Direct
end
