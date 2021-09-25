IO.puts "connecting"
{:ok, socket} = Libvirt.Hypervisor.connect("colosseum.sudov.im")

File.rm_rf!("images/")
File.mkdir_p!("images/")

# hostname
Libvirt.RPC.Call.connect_get_hostname(socket)
|> IO.inspect

# small test 1kb
# IO.puts "downloading 1kb file"
# Libvirt.Volume.download!(socket, %{ "key" => "/home/main/libvirt/test/user-data.yaml", "name" => "user-data.yaml", "pool" => "test"}, "images/user-data.yaml")

# medium test 300kb
# IO.puts "downloading 300kb file"
# Libvirt.Volume.download!(socket, %{ "key" => "/home/main/libvirt/test/cidata.iso", "name" => "cidata.iso", "pool" => "test"}, "images/cidata.iso")

# large test 1.3gb
# IO.puts "downloading 1.3gb file"
# Libvirt.Volume.download(socket, %{ "key" => "/home/main/libvirt/test/test.img", "name" => "test.img", "pool" => "test"}, "images/test.img")

# test that a faulty client that has no intention of reading its stream
# does not block other calls
# this works
# volume = %{ "key" => "/home/main/libvirt/test/user-data.yaml", "name" => "user-data.yaml", "pool" => "test"}
# Libvirt.RPC.Call.storage_vol_download(socket, %{"vol" => volume, "offset" => 0, "length" => 0, "flags" => 0})
# Libvirt.Network.list_all(socket)
# |> IO.inspect(label: :network1)

# {_,_,_,[_,_,_,_,[_,_,{_,[{_,state}]}]]} = :sys.get_status(socket)
# IO.inspect(state, label: :state)

### start async

## test that async calls do not block other calls
## this simulates a misbehaving client
# t = Task.async fn ->
  # Libvirt.Volume.download!(socket, %{ "key" => "/home/main/libvirt/test/cidata.iso", "name" => "cidata.iso", "pool" => "test"}, "/dev/null")
  # Libvirt.Volume.download!(socket, %{ "key" => "/home/main/libvirt/test/test.img", "name" => "test.img", "pool" => "test"}, "test.img")
# end
# IO.inspect(t, label: :task)

## this seems like it's getting back a full network payload, but it's not
## being parsed as a payload, this has to do with how we're reading somehow
## because it's expecting that Volume.download is handling this, not Network
# Libvirt.Network.list_all(socket)
# |> IO.inspect(label: :network2)

# {_,_,_,[_,_,_,_,[_,_,{_,[{_,state}]}]]} = :sys.get_status(socket)
# IO.inspect(state, label: :state)

## this seems to wait, but it's getting its own and the unfinished payloads
## I don't get why it's having issues, because the task is its own pid
# Task.await(t, 500_000)

# {_,_,_,[_,_,_,_,[_,_,{_,[{_,state}]}]]} = :sys.get_status(socket)
# IO.inspect(state, label: :state)

# IO.puts "uploading"
# name = Libvirt.UUID.gen_string()
# Libvirt.Volume.upload(
  # socket,
  # %{"key" => "/home/main/libvirt/test/#{name}", "name" => name, "pool" => "pool1"},
  # "user-data.yaml"
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
