IO.puts "connecting"
{:ok, socket} = Libvirt.Hypervisor.connect("colosseum.sudov.im")

Libvirt.RPC.Call.connect_get_hostname(socket)
|> IO.inspect(label: :'Libvirt.RPC.Call.connect_get_hostname')

Libvirt.Network.list_all(socket)
|> IO.inspect(label: :'Libvirt.Network.list_all')
