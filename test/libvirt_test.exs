defmodule LibvirtTest do
  use ExUnit.Case
  doctest Libvirt

  test "greets the world" do
    assert Libvirt.hello() == :world
  end
end
