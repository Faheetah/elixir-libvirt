Logger.configure(level: :info)
hv = "colosseum.sudov.im"

vol = %{
  "key" => "/home/main/libvirt/test/user-data.yaml",
  "name" => "user-data.yaml",
  "pool" => "test"
}

big_vol = %{
  "key" => "/home/main/libvirt/test/test.img",
  "name" => "test.img",
  "pool" => "test"
}
Benchee.run(
  %{
    "Libvirt.Network.list_all" => fn ->
      Libvirt.RPC.Backends.Direct.connect!(hv)
      |> Libvirt.Network.list_all()
    end,
    "Libvirt.Volume.download! small" => fn ->
      Libvirt.RPC.Backends.Direct.connect!(hv)
      |> Libvirt.Volume.download!(vol, "/dev/null")
    end,
    "Libvirt.Volume.Download! big download separate" => fn ->
      Libvirt.RPC.Backends.Direct.connect!(hv)
      |> Libvirt.Volume.download!(big_vol, "/dev/null")
    end,
  }, parallel: 8
)
