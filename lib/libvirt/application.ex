defmodule Libvirt.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      case Application.get_env(:libvirt, :rpc) |> Keyword.get(:backend) do
        Libvirt.Backends.Shared -> [Libvirt.Backends.HypervisorSupervisor]
        _ -> []
      end

    opts = [strategy: :one_for_one, name: Libvirt.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
