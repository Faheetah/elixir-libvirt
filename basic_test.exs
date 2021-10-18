Libvirt.connect!("colosseum.sudov.im")
|> Libvirt.connect_get_hostname()
|> IO.inspect(label: :'Libvirt.connect_get_hostname')

Libvirt.connect!("colosseum.sudov.im")
|> Libvirt.Network.list_all()
|> IO.inspect(label: :'Libvirt.Network.list_all')
