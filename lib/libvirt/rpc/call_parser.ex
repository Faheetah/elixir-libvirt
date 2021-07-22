defmodule Libvirt.RPC.CallParser do
  @moduledoc false

  import NimbleParsec
  # https://github.com/libvirt/libvirt/blob/c8238579fb0b1c3affbd77749ae2b2c4dfafb2d6/src/remote/remote_protocol.x#L455

  @space 0x0020
  @tab 0x009

  whitespace = utf8_char([@space, @tab, ?\n])

  ignore_whitespace =
    lookahead(whitespace)
    |> repeat(ignore(whitespace))

  ignore_comment =
    ignore(string("/*"))
    |> optional(ignore(string("*")))
    |> concat(ignore_whitespace)
    |> repeat(
      lookahead_not(string("*/"))
      |> utf8_char([])
    )
    |> ignore()
    |> ignore(string("*/"))

  maybe_stream_comment =
    ignore(string("/*"))
    |> optional(ignore(string("*")))
    |> concat(ignore_whitespace)
    |> repeat(
      lookahead_not(string("*/"))
      |> choice([
        string("writestream"),
        string("readstream"),
        ignore(utf8_char([]))
      ])
    )
    |> ignore(string("*/"))
    |> concat(ignore_whitespace)

  procedure =
    optional(maybe_stream_comment)
    |> utf8_string([?A..?Z, ?0..?9, ?_], min: 1)
    |> ignore(whitespace)
    |> ignore(string("="))
    |> ignore(whitespace)
    |> integer(min: 1)
    |> optional(ignore(string(",")))
    |> tag(:procedure)

  remote_procedures =
    ignore(string("enum remote_procedure {"))
    |> repeat(
      choice([ignore_whitespace, procedure, ignore_comment])
    )
    |> ignore(string("}"))

  const =
    string("const")
    |> ignore(whitespace)
    |> utf8_string([?A..?Z, ?0..?9, ?_], min: 1)
    |> ignore(whitespace)
    |> choice([integer(min: 1), utf8_string([?A..?Z, ?0..?9, ?_], min: 1)])
    |> string(";")

  struct_value =
    optional(ignore_whitespace)
    |> repeat(
      lookahead_not(string(";"))
      |> choice([
        ignore_whitespace,

        utf8_string([?a..?z, ?_], min: 1)
        |> ignore(string("<"))
        |> utf8_string([?A..?Z, ?_], min: 1)
        |> ignore(string(">"))
        |> tag(:list),

        utf8_string([?a..?z, ?A..?Z, ?_], min: 1)
      ])
    )
    |> ignore(string(";"))
    |> optional(ignore_whitespace)
    |> optional(ignore_comment)
    |> optional(ignore_whitespace)
    |> wrap()

  struct =
    ignore(string("struct"))
    |> concat(ignore_whitespace)
    |> ignore(string("remote_"))
    |> utf8_string([?a..?z, ?_], min: 1)
    |> unwrap_and_tag(:name)
    |> optional(ignore_whitespace)
    |> ignore(string("{"))
    |> optional(ignore_whitespace)
    |> optional(ignore_comment)
    |> optional(ignore_whitespace)
    |> tag(repeat(struct_value), :fields)
    |> tag(:struct)

  defparsec :parse,
    choice([remote_procedures, struct, const, ignore(utf8_char([]))])
    |> repeat()

end
