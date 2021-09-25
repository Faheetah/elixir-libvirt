hv = "colosseum.sudov.im"

{:ok, persistent} = Libvirt.Hypervisor.connect(hv)

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
    "persistent" => fn ->
      Libvirt.Network.list_all(persistent)
    end,
    "separate" => fn ->
      {:ok, transient} = Libvirt.RPC.start_link(hv)
      Libvirt.Network.list_all(transient)
    end,
  }
)

Benchee.run(
  %{
    "download persistent" => fn ->
      Libvirt.Volume.download!(persistent, vol, "/dev/null")
    end,
    "download separate" => fn ->
      {:ok, transient} = Libvirt.RPC.start_link(hv)
      Libvirt.Volume.download!(transient, vol, "/dev/null")
    end,
  }
)

Benchee.run(
  %{
    "big download persistent" => fn ->
      Libvirt.Volume.download!(persistent, big_vol, "/dev/null")
    end,
    "big download separate" => fn ->
      {:ok, transient} = Libvirt.RPC.start_link(hv)
      Libvirt.Volume.download!(transient, big_vol, "/dev/null")
    end,
  }
)
