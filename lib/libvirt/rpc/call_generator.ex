defmodule Libvirt.RPC.CallGenerator do
  @moduledoc "Generate calls"

  require Libvirt.RPC.CallParser

  @doc "Generate RPC calls into the module"
  defmacro generate(version) do
    remote_protocol_data = fetch_remote_protocol_data(version)
    structs = filter_types(remote_protocol_data, :struct)
    procs = filter_types(remote_protocol_data, :procedure)
    gen_procs(procs, structs)
  end

  defp fetch_remote_protocol_data(version) do
    {:ok, remote_protocol_data, _, _, _, _} =
      Libvirt.RPC.RemoteAsset.fetch(version, "src/remote/remote_protocol.x")
      |> Libvirt.RPC.CallParser.parse()

    remote_protocol_data
  end

  defp filter_types(remote_protocol_data, type) do
    remote_protocol_data
    |> Stream.filter(fn {tag, _struct} -> tag == type end)
    |> Enum.map(fn {_tag, struct} -> struct end)
  end

  defp gen_procs(procedures, structs) do
    Enum.map(procedures, &generate_procedure(&1, structs))
  end

  defp generate_procedure([stream_type, name, id], structs) do
    base_name =
      name
      |> String.trim_leading("REMOTE_PROC_")
      |> String.downcase()

    arg_spec = get_fields_for_call(structs, base_name, "_args")
    return_spec = get_fields_for_call(structs, base_name, "_ret")

    name = String.to_atom(base_name)

    spec = Libvirt.RPC.Spec.generate(name, arg_spec, return_spec, stream_type)

    if arg_spec do
      if stream_type == "writestream" do
        quote do
          @doc """
          Calls #{unquote(name)} using Libvirt RPC

          Consumes a Stream type as the source to send to the Libvirt server, i.e. File.open/2
          """
          unquote(spec)

          def unquote(name)(socket, payload, stream) do
            payload_data = Libvirt.RPC.XDR.encode(payload, unquote(arg_spec))

            do_procedure(
              socket,
              unquote(id),
              unquote(stream_type),
              unquote(return_spec),
              payload_data,
              stream
            )
          end
        end
      else
        quote do
          @doc """
          Calls #{unquote(name)} using Libvirt RPC
          """
          unquote(spec)

          def unquote(name)(socket, payload) do
            payload_data = Libvirt.RPC.XDR.encode(payload, unquote(arg_spec))

            do_procedure(
              socket,
              unquote(id),
              unquote(stream_type),
              unquote(return_spec),
              payload_data
            )
          end
        end
      end
    else
      if stream_type == "writestream" do
        quote do
          @doc """
          Calls #{unquote(name)} using Libvirt RPC
          """
          unquote(spec)

          def unquote(name)(socket, stream) do
            do_procedure(socket, unquote(id), unquote(stream_type), unquote(return_spec), stream)
          end
        end
      else
        quote do
          @doc """
          Calls #{unquote(name)} using Libvirt RPC
          """
          unquote(spec)

          def unquote(name)(socket) do
            do_procedure(socket, unquote(id), unquote(stream_type), unquote(return_spec))
          end
        end
      end
    end
  end

  # @todo invert this, call_parser should be able to better format with stream types
  # also might check for the more explicit @writestream: 1 instead of "writestream"
  # then tag that with :readstream or :writestream, but this works for now
  defp generate_procedure([name, id], structs) do
    generate_procedure([nil, name, id], structs)
  end

  defp get_fields_for_call(structs, call_name, suffix) do
    struct = Enum.find(structs, [nil, nil], fn struct -> struct[:name] == call_name <> suffix end)
    struct[:fields]
  end
end
