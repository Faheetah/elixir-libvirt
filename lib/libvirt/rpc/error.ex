defmodule Libvirt.RPC.Error do
  @moduledoc false

  require Libvirt.RPC.ErrorParser
  Libvirt.RPC.ErrorParser.generate("6.0.0")

  # default virtErrorNumber
  def vir_error_number(number) when is_number(number),
    do: {:error, "no libvirt error found with number #{number}"}

  def vir_error_number(_), do: {:error, "error must be an integer"}
end
