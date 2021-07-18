defmodule Libvirt.RPC.CallGenerator do
  @moduledoc "Generate calls"

  require Libvirt.RPC.CallParser

  @readstreams [201, 209, 211, 296]
  @writestreams [148, 208, 215]

  def fetch_remote_protocol_data(version) do
    {:ok, remote_protocol_data, _, _, _, _} =
      Libvirt.RPC.RemoteAsset.fetch(version, "src/remote/remote_protocol.x")
      |> Libvirt.RPC.CallParser.parse()
    remote_protocol_data
  end

  def filter_types(remote_protocol_data, type) do
    Stream.filter(remote_protocol_data, fn {tag, _struct} -> tag == type end)
    |> Enum.map(fn {_tag, struct} -> struct end)
  end

  def get_fields_for_call(structs, call_name, suffix \\ "") do
    struct = Enum.find(structs, [nil, nil], fn struct -> struct[:name] == call_name <> suffix end)
    struct[:fields]
  end

  def get_extra_structs(structs) do
    Enum.filter(structs, fn s -> !String.ends_with?(s[:name], "_args") and !String.ends_with?(s[:name], "_ret") end)
  end

  def field_to_atom([f]), do: String.to_atom(f)
  def field_to_atom({:list, [f | _]}), do: String.to_atom(f)
  def field_to_atom(f), do: String.to_atom(f)

  def get_stream_type(id) do
    cond do
      Enum.member?(@readstreams, id) -> :read
      Enum.member?(@writestreams, id) -> :write
      true -> nil
    end
  end

  def generate_procedure([name, id], structs) do
    stream_type = get_stream_type(id)

    base_name =
      name
      |> String.trim_leading("REMOTE_PROC_")
      |> String.downcase()

    arg_spec = get_fields_for_call(structs, base_name, "_args")
    return_spec = get_fields_for_call(structs, base_name, "_ret")

    name = String.to_atom(base_name)

    spec = Libvirt.RPC.Spec.generate(name, arg_spec, return_spec)
    if arg_spec do
      quote do
        @doc """
        Calls #{unquote(name)} using Libvirt RPC

        Arg spec

        ```
        #{inspect unquote(arg_spec), pretty: true}
        ```

        Return spec

        ```
        #{inspect unquote(return_spec), pretty: true}
        ```
        """
        unquote(spec)
        def unquote(name)(socket, payload) do
          payload_data = Libvirt.RPC.XDR.encode(payload, unquote(arg_spec))
          do_procedure(socket, unquote(id), unquote(stream_type), unquote(return_spec), payload_data)
        end
      end

    else
      quote do
        @doc """
        Calls #{unquote(name)} using Libvirt RPC

        Arg spec

        ```
        nil
        ```

        Return spec

        ```
        #{inspect unquote(return_spec), pretty: true}
        ```
        """
        unquote(spec)
        def unquote(name)(socket) do
          do_procedure(socket, unquote(id), unquote(stream_type), unquote(return_spec))
        end
      end
    end
  end

  @doc "Generate RPC calls into the module"
  defmacro generate(version) do
    remote_protocol_data = fetch_remote_protocol_data(version)

    procedures = filter_types(remote_protocol_data, :procedure)
    structs = filter_types(remote_protocol_data, :struct)

    extra_structs = get_extra_structs(structs)

    generated_structs = Enum.map(extra_structs, fn struct ->
      quote do
        def get_struct("remote_#{unquote(struct[:name])}") do
          {:ok, unquote(struct[:fields])}
        end
      end
    end)

    not_found_generated_struct = quote do
      def get_struct(_) do
        {:error, :notfound}
      end
    end

    generated_procedures = Enum.map(procedures, &(generate_procedure(&1, structs)))

    generated_structs ++ [not_found_generated_struct] ++ generated_procedures
  end
end
