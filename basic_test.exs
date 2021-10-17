Libvirt.RPC.Backends.Direct.connect!("colosseum.sudov.im")
|> Libvirt.RPC.Call.connect_get_hostname()
|> IO.inspect(label: :'Libvirt.RPC.Call.connect_get_hostname')

Libvirt.RPC.Backends.Direct.connect!("colosseum.sudov.im")
|> Libvirt.Network.list_all()
|> IO.inspect(label: :'Libvirt.Network.list_all')
