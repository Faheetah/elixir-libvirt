defmodule Libvirt.RPC.TranslationGenerator do
  @moduledoc "Generate calls"

  require Libvirt.RPC.CallParser

  @doc "Generate RPC calls into the module"
  defmacro generate(version) do
    remote_protocol_data = fetch_remote_protocol_data(version)
    procs = filter_types(remote_protocol_data, :procedure)
    gen_translations(procs)
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

  defp gen_translations(procs) do
    procs
    |> Enum.map(fn proc ->
      [name, id] =
        case proc do
          [_, name, id] -> [name, id]
          p -> p
        end
      name =
        name
        |> String.trim_leading("REMOTE_PROC_")
        |> String.downcase()

      quote do
        @doc "#{unquote(id)} -> #{unquote(name)}"
        def proc_to_name(unquote(id)), do: unquote(name)
      end
    end)
  end
end
