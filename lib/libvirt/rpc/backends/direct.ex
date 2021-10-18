defmodule Libvirt.RPC.Backends.Direct do
  require Logger

  alias Libvirt.RPC.Packet

  @tcp_port 16_509
  @call_type %{0 => "call", 1 => "reply", 2 => "event", 3 => "stream"}
  @call_status %{0 => "ok", 1 => "error", 2 => "continue"}

  def connect!(host) do
    {:ok, socket} = connect(host)
    socket
  end

  def connect(host) do
    {:ok, socket} = :gen_tcp.connect(to_charlist(host), @tcp_port, [:binary, active: false])
    Libvirt.connect_open(socket, %{"name" => "", "flags" => 0})
    {:ok, socket}
  end

  def send(socket, packet, nil) do
    Logger.debug("#{inspect socket}:1:#{@call_type[packet.type]}:#{packet.size}:#{Libvirt.RPC.Translation.proc_to_name(packet.procedure)} #{@call_status[packet.status]} #{inspect packet.payload}")
    :ok = :gen_tcp.send(socket, Packet.encode_packet(packet))
    {:ok, <<size::32>>} = :gen_tcp.recv(socket, 4)
    {:ok, rest} = :gen_tcp.recv(socket, size - 4)
    {:ok, packet} = Packet.decode(<<size::32>> <> rest)
    Logger.debug("#{inspect socket}:1:#{@call_type[packet.type]}:#{packet.size}:#{Libvirt.RPC.Translation.proc_to_name(packet.procedure)} #{@call_status[packet.status]} #{inspect packet.payload}")
    {:ok, packet.payload}
  end

  def send(socket, packet, "readstream") do
    Stream.resource(
      fn ->
        Logger.debug("#{inspect socket}:1:#{@call_type[packet.type]}:#{packet.size}:#{Libvirt.RPC.Translation.proc_to_name(packet.procedure)} #{@call_status[packet.status]} #{inspect packet.payload}")
        :ok = :gen_tcp.send(socket, Packet.encode_packet(packet))
        {:ok, <<size::32>>} = :gen_tcp.recv(socket, 4)
        {:ok, rest} = :gen_tcp.recv(socket, size - 4)
        {:ok, packet} = Packet.decode(<<size::32>> <> rest)
        Logger.debug("#{inspect socket}:1:#{@call_type[packet.type]}:#{packet.size}:#{Libvirt.RPC.Translation.proc_to_name(packet.procedure)} #{@call_status[packet.status]} #{inspect packet.payload}")
        socket
      end,
      fn socket ->
        {:ok, <<size::32>>} = :gen_tcp.recv(socket, 4)
        {:ok, rest} = :gen_tcp.recv(socket, size - 4)
        {:ok, packet} = Packet.decode(<<size::32>> <> rest)

        Logger.debug("#{inspect socket}:1:#{@call_type[packet.type]}:#{packet.size}:#{Libvirt.RPC.Translation.proc_to_name(packet.procedure)} #{@call_status[packet.status]} #{inspect packet.payload}")

        if packet.type == 3 and packet.payload != nil do
          {[packet.payload], socket}
        else
          {:halt, socket}
        end
      end,
      fn socket ->
        Libvirt.connect_close(socket)
      end
    )
  end

  def send(socket, packet, "writestream", stream) do
    Logger.debug("#{inspect socket}:1:#{@call_type[packet.type]}:#{Libvirt.RPC.Translation.proc_to_name(packet.procedure)} #{@call_status[packet.status]} #{inspect packet.payload}")
    :ok = :gen_tcp.send(socket, Packet.encode_packet(packet))
    {:ok, <<size::32>>} = :gen_tcp.recv(socket, 4)
    {:ok, rest} = :gen_tcp.recv(socket, size - 4)
    {:ok, packet} = Packet.decode(<<size::32>> <> rest)
    Logger.debug("#{inspect socket}:1:#{@call_type[packet.type]}:#{Libvirt.RPC.Translation.proc_to_name(packet.procedure)} #{@call_status[packet.status]} #{inspect packet.payload}")

    Enum.each(stream, fn chunk ->
      :gen_tcp.send(socket, Packet.encode_packet(%{packet | type: 3, status: 2, payload: chunk}))
    end)

    Libvirt.connect_close(socket)
  end
end

