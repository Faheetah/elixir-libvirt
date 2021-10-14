defmodule Libvirt.RPC do
  def start_link(host, name \\ nil) do
    backend = Application.get_env(:libvirt, :rpc) |> Keyword.get(:backend)
    backend.start_link(host, name)
  end

  def send(pid, payload, stream_type) do
    backend = Application.get_env(:libvirt, :rpc) |> Keyword.get(:backend)
    backend.send(pid, payload, stream_type)
  end
end
