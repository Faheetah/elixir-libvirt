defmodule Libvirt.RPC.StructGenerator do
  @moduledoc "Generate calls"

  require Libvirt.RPC.CallParser

  @doc "Generate RPC calls into the module"
  defmacro generate(version) do
    remote_protocol_data = fetch_remote_protocol_data(version)
    filter_types(remote_protocol_data, :struct)
    structs = filter_types(remote_protocol_data, :struct)
    gen_structs(structs) ++ [not_found_struct()]
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

  defp gen_structs(structs) do
    structs
    |> Stream.filter(fn s ->
      !String.ends_with?(s[:name], "_args") and !String.ends_with?(s[:name], "_ret")
    end)
    |> Enum.map(fn struct ->
      quote do
        def get_struct("remote_#{unquote(struct[:name])}") do
          {:ok, unquote(struct[:fields])}
        end
      end
    end)
  end

  defp not_found_struct() do
    quote do
      def get_struct(_) do
        {:error, :notfound}
      end
    end
  end
end

