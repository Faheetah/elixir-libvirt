defmodule Libvirt.RPC.XDRTest do
  use ExUnit.Case, async: true
  alias Libvirt.RPC.XDR

  # Use IO.inspect to generate example payload data, i.e. binaries: :as_binaries for strings
  # Keep in mind that things like strings are zero padded to the right to align on an even 4 bytes
  describe "decoding" do
    test "string" do
      spec = [["remote_nonnull_string", "string"]]
      payload = <<0, 0, 0, 6, 115, 116, 114, 105, 110, 103, 0, 0>>
      expected = %{"string" => "string"}
      assert expected == XDR.decode(payload, spec)
    end

    test "integer" do
      spec = [["unsigned", "int", "int"]]
      assert XDR.decode(<<255, 255, 255, 255>>, spec) == %{"int" => 4294967295}
      assert XDR.decode(<<0, 0, 0, 0>>, spec) == %{"int" => 0}
      assert XDR.decode(<<1, 1, 1, 1>>, spec) == %{"int" => 16843009}
    end

    test "hyper" do
      spec = [["unsigned", "hyper", "hyper"]]
      assert XDR.decode(<<255, 255, 255, 255, 255, 255, 255, 255>>, spec) == %{"hyper" => 18446744073709551615}
    end

    test "array of strings with int" do
      spec = [["remote_nonnull_string", {:list, ["strings", ""]}], ["unsigned", "int", "ret"]]
      payload = <<
        0, 0, 0, 3, # length of array
        0, 0, 0, 2, 115, 116, 0, 0, # string, 2 bytes, "st"
        0, 0, 0, 2, 114, 105, 0, 0, # string, 2 bytes, "ri"
        0, 0, 0, 2, 110, 103, 0, 0, # string, 2 bytes, "ng"
        0, 0, 0, 1
      >>

      assert XDR.decode(payload, spec) == %{"strings" => ["st", "ri", "ng"], "ret" => 1}
    end
  end

  describe "translate (decode)" do
    test '["unsigned", "int", "int"]' do
      spec = ["unsigned", "int", "int"]
      payload = <<0, 0, 0, 5, 1, 1, 1, 1>>
      assert {"int", 5, <<1, 1, 1, 1>>} == XDR.translate(:decode, spec, payload)
    end
  end

  describe "decoding real world payloads" do
    test "decoding a list of networks" do
      spec = [
        ["remote_nonnull_network", {:list, ["nets", "REMOTE_NETWORK_LIST_MAX"]}],
        ["unsigned", "int", "ret"]
      ]
      payload = <<
        0, 0, 0, 1, # length of array
        0, 0, 0, 11, 104, 111, 115, 116, 45, 98, 114, 105, 100, 103, 101, # name: host-bridge
        0, 23, 158, 13, 62, 138, 7, 72, 82, 190, 66, 167, 163, 75, 133, 201, 220, # uuid: 179e0d3e-8a07-4852-be42-a7a34b85c9dc
        0, 0, 0, 1 # ret: 1
      >>
      expected = %{"nets" => [%{"name" => "host-bridge", "uuid" => "179e0d3e-8a07-4852-be42-a7a34b85c9dc"}], "ret" => 1}
      assert expected == XDR.decode(payload, spec)
    end
  end
end
