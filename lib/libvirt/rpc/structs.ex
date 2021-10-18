defmodule Libvirt.RPC.Structs do
  @moduledoc "Generate structs"

  require Libvirt.RPC.StructGenerator
  Libvirt.RPC.StructGenerator.generate("6.0.0")
end
