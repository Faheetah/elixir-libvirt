defmodule Libvirt.RPC do
  @moduledoc "RPC top level code to delegate to backends"

  def start_link(host, name \\ nil) do
    backend = Application.get_env(:libvirt, :rpc) |> Keyword.get(:backend)
    backend.start_link(host, name)
  end

  def connect(host) do
    backend = Application.get_env(:libvirt, :rpc) |> Keyword.get(:backend)
    backend.connect(host)
  end

  def connect(host, backend) do
    backend.connect(host)
  end

  def send(pid, payload, stream_type) do
    backend = Application.get_env(:libvirt, :rpc) |> Keyword.get(:backend)
    backend.send(pid, payload, stream_type)
  end

  def send(pid, payload, stream_type, stream) do
    backend = Application.get_env(:libvirt, :rpc) |> Keyword.get(:backend)
    backend.send(pid, payload, stream_type, stream)
  end
end
