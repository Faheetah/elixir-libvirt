defmodule Libvirt.Hypervisor do
  @moduledoc false

  defstruct [:id, :hostname]

  alias Libvirt.Backends.{HypervisorRegistry, HypervisorSupervisor}

  def list_hypervisors() do
    Registry.select(HypervisorRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  def connect(name) do
    HypervisorSupervisor.start_child(name)
  end

  def disconnect(name) do
    HypervisorSupervisor.terminate_child(name)
  end

  def get_socket(name) do
    {:ok, socket} = HypervisorSupervisor.get_pid(name)
    socket
  end
end
