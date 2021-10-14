alias Libvirt.RPC.Hex2Dec

lib_dump = File.read!("dumps/elixir-hostname.full.dump")
IO.inspect Hex2Dec.dump_to_packets(lib_dump, true)

cli_dump = File.read!("dumps/hostname.full.dump")
IO.inspect Hex2Dec.dump_to_packets(cli_dump, true)
