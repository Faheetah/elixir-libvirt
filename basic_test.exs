IO.puts "connecting"
{:ok, socket} = Libvirt.Hypervisor.connect("colosseum.sudov.im")

File.rm_rf!("images/")
File.mkdir_p!("images/")

Libvirt.RPC.Call.connect_get_hostname(socket)
|> IO.inspect

Libvirt.Network.list_all(socket)
|> IO.inspect(label: :network2)
