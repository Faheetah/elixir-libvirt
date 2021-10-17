File.rm_rf!("images/")
File.mkdir_p!("images/")

IO.puts "downloading 1kb file"
Libvirt.RPC.Backends.Direct.connect!("colosseum.sudov.im")
|> Libvirt.Volume.download(%{"key" => "/home/main/libvirt/test/user-data.yaml", "name" => "user-data.yaml", "pool" => "test"})
|> Enum.each(fn f -> IO.inspect f end)

IO.puts "downloading 300kb file"
Libvirt.RPC.Backends.Direct.connect!("colosseum.sudov.im")
|> Libvirt.Volume.download(%{"key" => "/home/main/libvirt/test/cidata.iso", "name" => "cidata.iso", "pool" => "test"})
|> Enum.each(fn f -> IO.inspect f end)

# too much spam
Logger.configure(level: :info)

IO.puts "downloading 1.3gb file"
Libvirt.RPC.Backends.Direct.connect!("colosseum.sudov.im")
|> Libvirt.Volume.download(%{"key" => "/home/main/libvirt/test/test.img", "name" => "test.img", "pool" => "test"}, file: "images/test.img")

Logger.configure(level: :debug)
