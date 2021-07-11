defmodule Libvirt.RPC.Hex2Dec do
  @moduledoc false

  import NimbleParsec

  @space 0x0020

  defparsec :parse_hex,
    eventually(ignore(utf8_char([?:])))
    |> lookahead_not(utf8_char([?\n]))
    |> repeat(choice([
      ignore(utf8_char([@space])),
      utf8_string([?0..?9, ?a..?f], 2)
    ])
    )
    |> eventually(ignore(utf8_char([?\n])))
    |> repeat()

  # this is admittedly pretty bad, but it is for debugging Libvirt RPC calls
  def hexdump_to_decimal(hex, as_string \\ false) do
    {:ok, parsed, "", _, _, _} = __MODULE__.parse_hex(hex)
    hex = parsed
    |> Enum.map(fn p ->
      p
      |> to_charlist
      |> List.to_integer(16)
    end)
    |> Enum.chunk_every(2)
    |> Enum.chunk_every(8)
    |> Enum.with_index
    |> Enum.flat_map(fn {hex, line} ->
      lineref = String.pad_leading(Integer.to_string(line), 3, ["0"])
      ["0x#{lineref}0": hex] end)

    if as_string do
      str = hex
      |> Enum.map(fn {ref, l} ->
        [
          ref,
          Enum.map(l, fn i ->
            i
            |> Enum.map(fn x -> String.pad_leading(Integer.to_string(x), 3) end)
            |> Enum.join(" ")
          end)
          |> Enum.join(" | ")
        ]
        |> Enum.join(": | ")
      end)
      |> Enum.join(" |\n")
      IO.puts str <> " |"
    else
      hex
    end
  end
end
