defmodule Libvirt.RPC.XDRTest do
  use ExUnit.Case, async: true
  alias Libvirt.RPC.XDR

  describe "decoding" do
    test "decoding a list of networks" do
      payload = <<0, 0, 0, 1, 0, 0, 0, 11, 104, 111, 115, 116, 45, 98, 114, 105, 100, 103, 101, 0, 23, 158, 13, 62, 138, 7, 72, 82, 190, 66, 167, 163, 75, 133, 201, 220, 0, 0, 0, 1>>
      spec = [
        ["remote_nonnull_network", {:list, ["nets", "REMOTE_NETWORK_LIST_MAX"]}],
        ["unsigned", "int", "ret"]
      ]
      expected = %{"nets" => [%{"name" => "host-bridge", "uuid" => "179e0d3e-8a07-4852-be42-a7a34b85c9dc"}], "ret" => 1}
      assert expected == XDR.decode(payload, spec)
    end
  end
end
