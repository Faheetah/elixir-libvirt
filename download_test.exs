IO.puts "connecting"
{:ok, socket} = Libvirt.Hypervisor.connect("colosseum.sudov.im")

IO.puts "downloading"
# small test 1kb
Libvirt.Volume.download!(socket, %{ "key" => "/home/main/libvirt/test/user-data.yaml", "name" => "user-data.yaml", "pool" => "test"}, "user-data.yaml")
# medium test 300kb
Libvirt.Volume.download!(socket, %{ "key" => "/home/main/libvirt/test/cidata.iso", "name" => "cidata.iso", "pool" => "test"}, "cidata.iso")
# large test 1.3gb
Libvirt.Volume.download(socket, %{ "key" => "/home/main/libvirt/test/test.img", "name" => "test.img", "pool" => "test"}, "test.img")

# IO.puts "uploading"
# name = Libvirt.UUID.gen_string()
# Libvirt.Volume.upload(
#   socket,
#   %{"key" => "/home/main/libvirt/test/#{name}", "name" => name, "pool" => "pool1"},
#   "user-data.yaml"
# )

# Libvirt.RPC.get_state(socket)
# name = Libvirt.UUID.gen_string()
# Libvirt.Volume.upload(
#   socket,
#   %{"key" => "/home/main/libvirt/test/#{name}", "name" => name, "pool" => "pool1"},
#   "cidata.iso"
# )

# IO.puts "final genserver state:"
# Libvirt.RPC.get_state(socket)
# |> IO.inspect
