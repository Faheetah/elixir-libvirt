Libvirt.connect!("localhost")
|> Libvirt.connect_get_hostname()
|> IO.inspect(label: :'Libvirt.connect_get_hostname')

Libvirt.connect!("localhost")
|> Libvirt.Network.list_all()
|> IO.inspect(label: :'Libvirt.Network.list_all')
