alias Libvirt.RPC.Hex2Dec

lib_dump = File.read!("elixir-hostname.full.dump")
IO.inspect Hex2Dec.dump_to_packets(lib_dump, true)

cli_dump = File.read!("hostname.full.dump")
IO.inspect Hex2Dec.dump_to_packets(cli_dump, true)
