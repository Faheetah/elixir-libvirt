# Libvirt

**TODO: Add description**

Note: If volume uploads are not working, ensure the source stream is in chunks of 262,148. For example: `File.stream!("some.img", [], 262_148)`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `libvirt` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:libvirt, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/libvirt](https://hexdocs.pm/libvirt).

