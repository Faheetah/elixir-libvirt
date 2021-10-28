defmodule Libvirt.RPC.Backends.Test do
  @moduledoc """
  This should be turned into something akin to the Shared type so connections
  can be left open and refreshed
  """

  def connect!(host) do
    {:ok, socket} = connect(host)
    socket
  end

  def connect(host) do
    socket = Process.get(:socket)
    if socket do
      {:ok, socket}
    else
      case Libvirt.RPC.Backends.Direct.connect(host, "test:///default", 57087) do
        {:ok, socket} ->
          Process.put(:socket, socket)
          {:ok, socket}

        error ->
          error
      end
    end
  end

  defdelegate send(socket, packet, type), to: Libvirt.RPC.Backends.Direct
  defdelegate send(socket, packet, type, stream), to: Libvirt.RPC.Backends.Direct
end
