defmodule Libvirt.RPC do
  @moduledoc """
  Libvirt RPC communication using the Libvirt RPC protocol

  See:

  https://libvirt.org/internals/rpc.html#wireexamplescallfd

  https://libvirt.org/git/?p=libvirt.git;a=blob_plain;f=src/remote/remote_protocol.x;hb=HEAD

  ```
  iex(1)> {:ok, socket} = Libvirt.RPC.start_link("host.example.com")
  {:ok, #PID<0.466.0>}
  iex(2)> Libvirt.RPC.Call.connect_get_hostname(socket)
  {:ok, %{"hostname" => "host"}}
  ```
  """

  use GenServer

  alias Libvirt.RPC.Packet

  @tcp_port 16_509

  def send(pid, packet, stream_type) do
    GenServer.call(pid, {:send, packet, stream_type})
  end

  def start_link(host, name \\ nil) do
    {:ok, socket} = GenServer.start_link(__MODULE__, %{host: to_charlist(host), socket: nil, serial: 1, requests: %{}}, name: name)
    Libvirt.RPC.Call.connect_open(socket, %{"name" => "", "flags" => 0})
    {:ok, socket}
  end

  @impl true
  def init(state) do
    tcp_connect(state)
  end

  @impl true
  def handle_cast(:reconnect, _state) do
    {:stop, :terminate}
  end

  @impl true
  def handle_cast({:receive, :read}, state) do
    {:ok, <<size::32>>} = :gen_tcp.recv(state.socket, 4)
    {:ok, rest} = :gen_tcp.recv(state.socket, size - 4)

    {:ok, packet} = Packet.decode(<<size::32>> <> rest)

    {:ok, caller, new_state} =
      if packet.type != 3 or packet.payload != nil do
        GenServer.cast(self(), {:receive, :read})
        get_caller(state, packet.serial)
      else
        get_and_remove_caller(state, packet.serial)
      end

    GenServer.reply(caller, packet.payload)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:receive, _stream_type}, state) do
    {:ok, <<size::32>>} = :gen_tcp.recv(state.socket, 4)
    {:ok, rest} = :gen_tcp.recv(state.socket, size - 4)
    {result, packet} = Packet.decode(<<size::32>> <> rest)
    {:ok, caller, new_state} = get_and_remove_caller(state, packet.serial)
    GenServer.reply(caller, {result, packet.payload})
    {:noreply, new_state}
  end

  # @todo implement stream_type = :read
  @impl true
  def handle_call({:send, packet, stream_type}, from, state) do
    new_state = add_caller(state, from)
    # @todo if the server receives an incomplete response, it will hang
    # need to find a way to ensure a full request is sent or fail
    send_request(state, packet)
    GenServer.cast(self(), {:receive, stream_type})
    {:noreply, new_state}
  end

  def handle_info({:DOWN, _, :process, client, _}, %{requests: requests} = state) do
    {:noreply, %{state | requests: Map.delete(requests, Enum.filter(requests, fn _, {pid, _} -> pid == client end))}}
  end

  @impl true
  def handle_info({:tcp_closed, _port}, state) do
    {:noreply, %{state | socket: nil}}
  end

  defp send_request(state, packet) do
    :ok = :gen_tcp.send(state.socket, Packet.encode_packet(%{packet | serial: state.serial}))
  end

  defp add_caller(%{requests: requests, serial: serial} = state, {pid, _} = from) do
    ref = Process.monitor(pid)
    %{state | serial: serial + 1, requests: Map.put(requests, serial, {from, ref})}
  end

  defp get_caller(%{requests: requests} = state, serial) do
    {client, _} = requests[serial]
    {:ok, client, state}
  end

  defp get_and_remove_caller(%{requests: requests} = state, serial) do
    {client, ref} = requests[serial]
    Process.demonitor(ref)
    {:ok, client, %{state | requests: Map.delete(requests, serial)}}
  end

  defp tcp_connect(%{host: host} = state) do
    case :gen_tcp.connect(host, @tcp_port, [:binary, active: false]) do
      {:ok, socket} -> {:ok, %{state | socket: socket}}
      error -> error
    end
  end
end
