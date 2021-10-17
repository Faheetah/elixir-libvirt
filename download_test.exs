File.rm_rf!("images/")
File.mkdir_p!("images/")

## small test 1kb
# {:ok, socket} = Libvirt.RPC.Backends.Direct.connect('colosseum.sudov.im')
# IO.puts "downloading 1kb file"
# Libvirt.Volume.download!(socket, %{ "key" => "/home/main/libvirt/test/user-data.yaml", "name" => "user-data.yaml", "pool" => "test"}, "images/user-data.yaml")
# |> Enum.each(fn f -> IO.inspect f end)

## medium test 300kb
# {:ok, socket} = Libvirt.RPC.Backends.Direct.connect('colosseum.sudov.im')
# IO.puts "downloading 300kb file"
# Libvirt.Volume.download!(socket, %{ "key" => "/home/main/libvirt/test/cidata.iso", "name" => "cidata.iso", "pool" => "test"}, "images/cidata.iso")
# |> Enum.each(fn f -> IO.inspect f end)

## large test 1.3gb
# {:ok, socket} = Libvirt.RPC.Backends.Direct.connect('colosseum.sudov.im')
# IO.puts "downloading 1.3gb file"
# Libvirt.Volume.download(socket, %{ "key" => "/home/main/libvirt/test/test.img", "name" => "test.img", "pool" => "test"}, "images/test.img")
# |> Stream.into(File.stream!("images/test.img"))
# |> Stream.run()

IO.puts "uploading"
name = Libvirt.UUID.gen_string()
{:ok, socket} = Libvirt.RPC.Backends.Direct.connect("colosseum.sudov.im")
Libvirt.Volume.upload(
  socket,
  %{"key" => "/home/main/libvirt/test/#{name}", "name" => name, "pool" => "pool1"},
  "user-data.yaml"
)

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
