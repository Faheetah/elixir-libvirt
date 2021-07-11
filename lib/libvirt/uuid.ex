defmodule Libvirt.UUID do
  @moduledoc false

  def gen_binary() do
    <<a::48, b::12, c::62, _discard::6>> = :crypto.strong_rand_bytes(16)
    <<a::48, 4::4, b::12, 2::2, c::62>>
  end

  # this is duplicated from XDR
  # uuid generation is pretty trivial, and I'd like to minimize libvirt dependencies
  # DRY up later
  def gen_string() do
    <<
      a::8, b::8, c::8, d::8,
      e::8, f::8,
      g::8, h::8,
      i::8, j::8,
      k::8, l::8, m::8, n::8, o::8, p::8
    >> = gen_binary()

    [a, b, c, d, "-", e, f, "-", g, h, "-", i, j, "-", k, l, m, n, o, p]
    |> Enum.map(fn i ->
      if is_integer(i) do
        Integer.to_string(i, 16)
        |> String.downcase()
        |> String.pad_leading(2, "0")
      else
        i
      end
    end)
    |> List.to_string()
  end
end
