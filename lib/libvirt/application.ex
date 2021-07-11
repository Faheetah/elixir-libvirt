defmodule Libvirt.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Libvirt.HypervisorSupervisor
    ]

    opts = [strategy: :one_for_one, name: Libvirt.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
