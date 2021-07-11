defmodule Libvirt.RPC.Call do
  @moduledoc false

  require Libvirt.RPC.CallGenerator
  Libvirt.RPC.CallGenerator.generate("6.0.0")
end
