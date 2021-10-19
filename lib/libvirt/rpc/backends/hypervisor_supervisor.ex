defmodule Libvirt.RPC.Backends.HypervisorSupervisor do
  @moduledoc false

  use DynamicSupervisor

  alias Libvirt.RPC.Backends.HypervisorRegistry

  def start_link(_init_arg) do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: __MODULE__)
    Registry.start_link(keys: :unique, name: Libvirt.RPC.Backends.HypervisorRegistry)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(name) do
    case Registry.lookup(HypervisorRegistry, name) do
      [] ->
        {:ok, pid} =
          DynamicSupervisor.start_child(__MODULE__, {Libvirt.RPC.Backends.Shared, name})

        Registry.register(HypervisorRegistry, name, pid)
        {:ok, pid}

      [{_, pid}] ->
        if Process.alive?(pid) do
          {:ok, pid}
        else
          Registry.unregister(HypervisorRegistry, name)

          {:ok, pid} =
            DynamicSupervisor.start_child(__MODULE__, {Libvirt.RPC.Backends.Shared, name})

          Registry.register(HypervisorRegistry, name, pid)
          {:ok, pid}
        end
    end
  end

  def terminate_child(name) do
    case Registry.lookup(HypervisorRegistry, name) do
      [] ->
        {:error, :not_found}

      [{_, pid}] ->
        Registry.unregister(HypervisorRegistry, name)
        DynamicSupervisor.terminate_child(__MODULE__, pid)
    end
  end

  def get_pid(name) do
    case Registry.lookup(HypervisorRegistry, name) do
      [] -> {:error, :not_found}
      [{_, pid}] -> {:ok, pid}
    end
  end
end
