defmodule Libvirt.RPC.Spec do
  @moduledoc false

  @stream_type {{:., [], [{:__aliases__, [alias: false], [:Enumerable]}, :t]}, [], []}

  def generate(function_name, arg_spec, ret_spec, stream_type) do
    {:@, [], [
      {:spec, [], [
        {:"::", [], [
          {
            function(function_name),
            [],
            # either of
            # [pid()]
            # [pid(), {:fun, [], []}]
            # [pid(), %{...}]
            # [pid(), %{...}, {:fun, [], []}]
            build_arg_spec(arg_spec, stream_type)
          },
          # either of:
          # nil
          # {:fun, [], []}
          # %{...}
          # [%{...}, {fun, [], []}]
          build_ret_spec(ret_spec, stream_type)
        ]}
      ]}
    ]}
  end

  def build_arg_spec(nil, nil), do: [pid()]
  def build_arg_spec(nil, _), do: [pid(), @stream_type]
  def build_arg_spec(fields, "writestream") do
    [
      pid(),
      fields
      |> Enum.map(&map_fields/1)
      |> then(fn f -> {:%{}, [], f} end),
      @stream_type
    ]
  end
  def build_arg_spec(fields, _) do
    [
      pid(),
      fields
      |> Enum.map(&map_fields/1)
      |> then(fn f -> {:%{}, [], f} end)
    ]
  end

  def build_ret_spec(nil, "readstream"), do: @stream_type
  def build_ret_spec(nil, _), do: nil
  def build_ret_spec(fields, "readstream") do
    {build_ret_spec(fields, nil), build_ret_spec(nil, "readstream")}
  end
  def build_ret_spec(fields, _) do
    fields
    |> Enum.map(&map_fields/1)
    |> then(fn f -> {:%{}, [], f} end)
  end

  def map_fields(f) do
    map_field(field(f))
  end

  def map_field({name, val}) do
    n =
      case name do
        s when is_binary(s) -> String.to_atom(s)
        s -> s
      end

    quote do
      {unquote(n), unquote(val)}
    end
  end
  def map_field(:unknown), do: quote(do: any())

  # lists for primitives
  # ["unsigned", "int", {:list, ["keycodes", "REMOTE_DOMAIN_SEND_KEY_MAX"]}]}
  def field(["unsigned", _, {:list, [name, _]}]), do: {name, quote(do: [integer()])}

  # lists for existing structs
  def field([x, y, {:list, l}]), do: field([[x, y], {:list, l}])

  def field([f, {:list, [name, _]}]) do
    case field([f, name]) do
      {_, ff} ->
        quote do
          {unquote(name), [unquote(ff)]}
        end
    end
  end

  def field(["signed", _, name]), do: {name, quote(do: integer())}
  def field(["unsigned", _, name]), do: {name, quote(do: integer())}
  def field(["int", name]), do: {name, quote(do: integer())}
  def field(["char", name]), do: {name, quote(do: integer())}
  def field(["hyper", name]), do: {name, quote(do: integer())}
  def field(["remote_nonnull_string", name]), do: {name, quote(do: String.t())}
  def field(["remote_string", name]), do: {name, quote(do: String.t())}
  def field(["remote_uuid", name]), do: {name, quote(do: String.t())}
  def field(["opaque", name]), do: {name, quote(do: [String.t()])}

  # @todo spec these out better
  # they should not be hard coded, but there is a catch22 that we can't use Libvirt.RPC.Call.get_struct/1
  # because it doesn't exist yet
  def field(["remote_typed_param", name]) do
    {name, quote(do:
      %{field: String.t(), value: String.t | boolean() | integer()}
    )}
  end

  def field(["remote_domain", name]), do: field(["remote_nonnull_domain", name])
  def field(["remote_nonnull_domain", name]) do
    {name, quote(do: %{name: String.t(), uuid: String.t()})}
  end

  def field(["remote_network", name]), do: field(["remote_nonnull_network", name])
  def field(["remote_nonnull_network", name]) do
    {name, quote(do: %{name: String.t(), uuid: String.t()})}
  end

  def field(["remote_network_port", name]), do: field(["remote_nonnull_network_port", name])
  def field(["remote_nonnull_network_port", name]) do
    {name, quote(do: %{net: %{name: String.t(), uuid: String.t()}, uuid: String.t()})}
  end

  def field(["remote_nwfilter_binding", name]), do: field(["remote_nonnull_nwfilter_binding", name])
  def field(["remote_nonnull_nwfilter_binding", name]) do
    {name, quote(do: %{name: String.t(), uuid: String.t()})}
  end

  def field(["remote_nwfilter", name]), do: field(["remote_nonnull_nwfilter", name])
  def field(["remote_nonnull_nwfilter", name]) do
    {name, quote(do: %{portdev: String.t(), filtername: String.t()})}
  end

  def field(["remote_nonnull_interface", name]) do
    {name, quote(do: %{name: String.t(), mac: String.t()})}
  end

  def field(["remote_storage_pool", name]), do: field(["remote_nonnull_storage_pool", name])
  def field(["remote_nonnull_storage_pool", name]) do
    {name, quote(do: %{name: String.t(), uuid: String.t()})}
  end

  def field(["remote_storage_volume", name]), do: field(["remote_nonnull_storage_volume", name])
  def field(["remote_nonnull_storage_vol", name]) do
    {name, quote(do: %{pool: String.t(), name: String.t(), key: String.t()})}
  end

  def field(["remote_node_device", name]), do: field(["remote_nonnull_node_device", name])
  def field(["remote_nonnull_node_device", name]) do
    {name, quote(do: %{pool: String.t(), name: String.t(), key: String.t()})}
  end

  def field(["remote_secret", name]), do: field(["remote_nonnull_secret", name])
  def field(["remote_nonnull_secret", name]) do
    {name, quote(do: %{uuid: String.t(), usageType: integer(), usageID: String.t()})}
  end

  def field(["remote_domain_interface", name]) do
    {name, quote(do: %{
      name: String.t(),
      hwaddr: String.t(),
      addrs: [%{type: integer, addr: String.t(), prefix: integer()}]
    })}
  end

  def field(["remote_domain_iothread_info", name]) do
    {name, quote(do: %{
      iothread_id: integer(),
      cpumap: [String.t()]
    })}
  end

  def field(["remote_domain_fsinfo", name]) do
    {name, quote(do: %{
      mountpoint: String.t(),
      name: String.t(),
      fstype: String.t(),
      dev_aliases: [String.t()]
    })}
  end

  def field(["remote_network_dhcp_lease", name]) do
    {name, quote(do: %{
      iface: String.t(),
      expirytime: String.t(),
      type: integer(),
      mac: String.t(),
      iaid: String.t(),
      ipaddr: String.t(),
      prefix: integer(),
      hostname: String.t(),
      clientid: String.t()
    })}
  end

  def field(["remote_domain_get_security_label_ret", name]) do
    {name, quote(do: %{
      # char?
      label: [integer()],
      enforcing: integer()
    })}
  end

  def field(["remote_domain_disk_error", name]) do
    {name, quote(do: %{
      disk: String.t(),
      error: integer()
    })}
  end

  def field(["remote_node_get_memory_stats", name]) do
    {name, quote(do: %{
      field: String.t(),
      value: integer()
    })}
  end

  def field(["remote_node_get_cpu_stats", name]) do
    {name, quote(do: %{
      field: String.t(),
      value: integer()
    })}
  end

  def field(["remote_vcpu_info", name]) do
    {name, quote(do: %{
      number: integer(),
      state: integer(),
      cpu_time: integer(),
      cpu: integer()
    })}
  end

  def field(["remote_auth_type", name]) do
    {name, quote(do: integer())}
  end

  def field(["remote_domain_memory_stat", name]) do
    {name, quote(do: %{
      tag: integer(),
      val: integer()
    })}
  end

  def field(["remote_nonnull_domain_checkpoint", name]) do
    {name, quote(do: %{name: String.t(), dom: %{name: String.t(), uuid: String.t()}})}
  end

  def field(["remote_nonnull_domain_snapshot", name]) do
    {name, quote(do: %{name: String.t(), dom: %{name: String.t(), uuid: String.t()}})}
  end

  # default to warn and move on
  def field([field | name]) do
    stacktrace = [{Libvirt.RPC.Spec, :field, 1, [file: 'spec.ex', line: 81]}]
    IO.warn "attempting to parse #{name}, spec field for #{field} not implemented", stacktrace
    str = quote(do: any())
    {str, str}
  end

  def function(func_name), do: func_name

  def pid(), do: {:pid, [], []}
end
