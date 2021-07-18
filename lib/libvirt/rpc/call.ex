defmodule Libvirt.RPC.Call do
  @moduledoc """
  These modules are generated from the Libvirt RPC spec.  See documentation for
  `Libvirt.RPC.CallGenerator` for information on how the code is generated.

  Arg spec and return spec match the XDR serialization formats referenced in the Libvirt code
  that are tagged with `_arg` and `_ret`, respectively. These specs are only important for
  internal functionality for translating the data. They are included in each function's
  documentation for troubleshooting purposes. If the arg spec is nil, no arguments are
  required (the function has an arity of 1), whereas if the return spec is nil, nothing
  will be returned.

  The format for the arg spec is

  ```
  # each item in the list is a separate argument
  [
    # the type can be multiple items but the name is last
    [type..., argument name],
    # a variable "flags" with a value to be decoded as unsigned int
    ["unsigned", "int", "flags"]
    # some types are lists with the first param being the type, i.e. a string
    [
      "remote_nonnull_string",
      # lists are output specially with a tuple tagged as :list
      # Inside of the list is the name of the list along with a const for the max
      # value of the list
      {:list, ["mountpoints", "REMOTE_DOMAIN_FSFREEZE_MOUNTPOINTS_MAX"]}
    ],
  ]
  ```

  Each function takes a TCP socket and a payload given as a map. Some functions do not
  require a payload and only have an arity of 1, the socket. Specs are provided for
  the args and return specs, as Elixir will see them before encoding and after decoding.
  """

  require Libvirt.RPC.CallGenerator
  Libvirt.RPC.CallGenerator.generate("6.0.0")

  defp do_procedure(socket, id, stream_type, return_spec, payload \\ nil) do
    packet = %Libvirt.RPC.Packet{
      # program is hard coded for Libvirt
      program: 0x20008086,
      # so is version
      version: 1,
      procedure: id,
      type: 0,
      serial: 0,
      status: 0,
      payload: payload
    }
    Libvirt.RPC.send(socket, packet, stream_type)
    |> receive_data(return_spec)
  end

  defp receive_data({:ok, payload}, return_spec) do
    {:ok, Libvirt.RPC.XDR.decode(payload, return_spec)}
  end

  defp receive_data(error, _), do: error
end
