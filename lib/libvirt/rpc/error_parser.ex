defmodule Libvirt.RPC.ErrorParser do
  @moduledoc false

  import NimbleParsec

  @space 0x0020
  @tab 0x009

  ifdef =
    concat(
      ignore(string("# ifdef")),
      eventually(ignore(string("# endif")))
    )

  comment =
    lookahead_not(string(" */"))
    |> choice([
      ignore(string("/* ")),
      ignore(string("\n")) |> string(" "),
      ignore(utf8_string([@space, @tab], min: 2)),
      utf8_string([], 1)
    ])
    |> repeat()
    |> ignore(string(" */"))
    |> wrap()
    |> reduce({Enum, :join, [""]})

  no_comment =
    lookahead(string("\n"))
    |> string("")

  error =
    eventually(utf8_string([?A..?Z, ?_], min: 1))
    |> eventually(integer(min: 1))
    |> eventually(ignore(string(",")))
    |> choice([no_comment, comment])
    |> optional(ifdef)

  find_enum =
    eventually(string("typedef enum {"))
    |> lookahead(string("virErrorNumber"))

  ignore_enum =
    ignore(eventually(string("typedef enum {")))
    |> lookahead_not(string("virErrorNumber"))

  defparsec :parse,
    choice([find_enum, ignore_enum])
    |> repeat()
    |> concat(repeat(error))

  def parse_errors(version) do
    rpc = Libvirt.RPC.RemoteAsset.fetch(version,  "include/libvirt/virterror.h")

    {:ok, call_list, _, _, _, _} = Libvirt.RPC.ErrorParser.parse(rpc)
    call_list
    |> Enum.chunk_every(3)
  end

  defmacro generate(version) do
    Enum.map(parse_errors(version), fn [key, id, message] ->
      quote do
      # def vir_error_number(3), do: {:VIR_ERR_NO_SUPPORT, "no support for this function"}
        def vir_error_number(unquote(id)) when is_number(unquote(id)), do: unquote({String.to_atom(key), message})
      end
    end)
  end
end
