defmodule Libvirt.RPC.Hex2Dec do
  @moduledoc false

  import NimbleParsec

  @space 0x0020

  parse_hex_block =
    ignore(string("        0x"))
    |> ignore(integer(4))
    |> ignore(string(":  "))
    |> lookahead_not(utf8_char([?\n]))
    |> repeat(choice([
      ignore(utf8_char([@space])),
      utf8_string([?0..?9, ?a..?f], 2)
    ])
    )
    |> eventually(ignore(utf8_char([?\n])))

  defparsec :parse_hex,
    parse_hex_block
    |> repeat()

  defparsec :parse_dump,
    ignore(utf8_string([?0..?9, ?:, ?.], 15))
    |> ignore(utf8_char([@space]))
    |> ignore(string("IP"))
    |> eventually(ignore(string("length ")))
    |> unwrap_and_tag(integer(min: 1), :length)
    |> eventually(ignore(utf8_char([?\n])))
    |> unwrap_and_tag(eventually(utf8_string([?0..?9, ?.], min: 8)), :source_ip)
    |> ignore(utf8_char([@space]))
    |> ignore(utf8_char([?>]))
    |> ignore(utf8_char([@space]))
    |> unwrap_and_tag(eventually(utf8_string([?0..?9, ?.], min: 8)), :dest_ip)
    |> eventually(ignore(utf8_char([?\n])))
    |> tag(repeat(parse_hex_block), :hex)
    |> wrap()
    |> repeat()

  def dump_to_raw(dump) do
    {:ok, parsed, "", _, _, _} = __MODULE__.parse_dump(dump)
    parsed
  end

  def hexdump_to_raw(hex) do
    {:ok, parsed, "", _, _, _} = __MODULE__.parse_hex(hex)
    parsed
  end

  def dump_to_packets(data, filter_invalid_packets \\ false) do
    data
    |> dump_to_raw()
    |> Enum.with_index()
    |> Enum.map(fn {dump, i} ->
      case parsed_hex_to_packet(dump[:hex]) do
        {:ok, packet} -> Keyword.put(dump, :hex, packet)
        {:error, _} -> dump
      end
      |> Keyword.put(:dest_ip, parse_address(dump[:dest_ip]))
      |> Keyword.put(:source_ip, parse_address(dump[:source_ip]))
      |> Keyword.put(:packet, i + 1)
    end)
    |> Enum.reject(fn x -> is_list(x[:hex]) and filter_invalid_packets end)
  end

  def parse_address(address) do
    [ip1, ip2, ip3, ip4, port] = String.split(address, ".")
    {port, _} = Integer.parse(port)
    [ip: Enum.join([ip1, ip2, ip3, ip4], "."), port: port]
  end

  def hexdump_to_packet(hex) do
    {:ok, parsed, "", _, _, _} = __MODULE__.parse_hex(hex)
    parsed_hex_to_packet(parsed)
  end

  def parsed_hex_to_packet(parsed) do
    parsed
    |> Enum.map(fn p ->
      p
      |> to_charlist
      |> List.to_integer(16)
    end)
    |> Enum.drop(52)
    |> Enum.into(<<>>, fn bit -> <<bit::8>> end)
    |> Libvirt.RPC.Packet.decode
  end

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
