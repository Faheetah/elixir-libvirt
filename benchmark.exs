Logger.configure(level: :info)
hv = "localhost"

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
      Libvirt.Backends.Direct.connect!(hv)
      |> Libvirt.Network.list_all()
    end,
  }, parallel: 8
)
