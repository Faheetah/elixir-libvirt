File.rm_rf!("images/")
File.mkdir_p!("images/")

socket = Libvirt.RPC.Backends.Direct.connect!("colosseum.sudov.im")

Libvirt.Volume.download(socket, %{"key" => "/home/main/libvirt/test/user-data.yaml", "name" => "user-data.yaml", "pool" => "test"}, file: "images/user-data.yaml")

name = Libvirt.UUID.gen_string()
{:ok, stat} = File.stat("images/user-data.yaml")
volume = %Libvirt.Volume{
  name: name,
  path: "/home/main/libvirt/test/#{name}",
  pool: "test",
  capacity: stat.size,
  unit: "B"
}

socket = Libvirt.RPC.Backends.Direct.connect!("colosseum.sudov.im")
Libvirt.Volume.create(socket, volume)
Libvirt.Volume.upload(socket, volume, file: "images/user-data.yaml")




socket = Libvirt.RPC.Backends.Direct.connect!("colosseum.sudov.im")

Libvirt.Volume.download(socket, %{"key" => "/home/main/libvirt/test/cidata.iso", "name" => "cidata.iso", "pool" => "test"}, file: "images/cidata.iso")

name = Libvirt.UUID.gen_string()
{:ok, stat} = File.stat("images/cidata.iso")
volume = %Libvirt.Volume{
  name: name,
  path: "/home/main/libvirt/test/#{name}",
  pool: "test",
  capacity: stat.size,
  unit: "B"
}

socket = Libvirt.RPC.Backends.Direct.connect!("colosseum.sudov.im")
Libvirt.Volume.create(socket, volume)
Libvirt.Volume.upload(socket, volume, file: "images/cidata.iso")


Logger.configure(level: :info)

socket = Libvirt.RPC.Backends.Direct.connect!("colosseum.sudov.im")

Libvirt.Volume.download(socket, %{"key" => "/home/main/libvirt/test/test.img", "name" => "test.img", "pool" => "test"}, file: "images/test.img")

name = Libvirt.UUID.gen_string()
{:ok, stat} = File.stat("images/test.img")
volume = %Libvirt.Volume{
  name: name,
  path: "/home/main/libvirt/test/#{name}",
  pool: "test",
  capacity: stat.size,
  unit: "B"
}

Libvirt.Volume.create(socket, volume)
Libvirt.Volume.upload(socket, volume, file: "images/test.img")

Logger.configure(level: :debug)
