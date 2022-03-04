defmodule Libvirt.RPC.XDR do
  @moduledoc false

  def encode(nil, _), do: nil

  def encode(payload, spec) do
    results =
      Enum.map(spec, fn arg ->
        try do
          translate(:encode, arg, payload)
        rescue
          # specifically for encode/decode errors
          error in ArgumentError ->
            reraise format_error(arg, payload, error), __STACKTRACE__

          error in FunctionClauseError ->
            reraise format_error(arg, payload, error), __STACKTRACE__
        end
      end)

    case Enum.filter(results, &filter_error/1) do
      [] -> Enum.join(results)
      errors -> throw Enum.join(Enum.map(errors, fn {:error, error} -> error end), "\n")
    end
  end

  defp filter_error({:error, error}), do: error
  defp filter_error(_), do: nil

  def decode(nil, _), do: nil

  def decode(payload, spec) do
    {result, ""} =
      Enum.reduce(spec, {%{}, payload}, fn arg, {acc, rest} ->
        translated =
          try do
            translate(:decode, arg, rest)
          rescue
            # specifically for encode/decode errors
            error in ArgumentError ->
              reraise format_error(arg, payload, error), __STACKTRACE__

            error in FunctionClauseError ->
              reraise format_error(arg, rest, error), __STACKTRACE__
          end

        case translated do
          {:error, error} -> throw("#{error}, translate failed on #{inspect(arg)}")
          {name, val, rest} -> {Map.merge(acc, %{name => val}), rest}
        end
      end)

    result
  end

  def format_error(args, payload, original_error) do
    # might not work for {:list, list}, fix that when we get to it
    IO.puts("Warning: if the following output does not display accurately, fix xdr.ex:43")

    bad_args =
      args
      |> Enum.map(&("\"" <> &1 <> "\""))
      |> Enum.join(", ")

    payload_string =
      payload
      |> inspect(pretty: true)
      |> String.split("\n")
      |> Enum.map(&("         " <> &1))
      |> Enum.join("\n")

    original_error = Exception.format(:error, original_error)

    Enum.join(
      [
        "Error parsing spec:",
        "      spec:\n        [#{bad_args}]",
        "      payload:\n#{payload_string}",
        "#{original_error}"
      ],
      "\n\n"
    )
  end

  # a nil is a nil regardless of type
  # might need better checks here?
  def translate(:encode, _, nil), do: <<>>

  def translate(:decode, [_, {:list, [name, _max]}], <<0, 0, 0, 0, rest::binary>>) do
    {name, [], rest}
  end

  # ensuring that the char length matches the spec
  def translate(:encode, ["char", {:char, [name, length]}], data) do
    IO.inspect String.length(data)
    if String.length(data)*4 == length do
      data
    else
      throw "Char encoded with wrong length: #{name}"
    end
  end

  def translate(:decode, ["char", {:char, [name, length]}], data) do
    {length, _} = Integer.parse(length)

    {char, rest} =
      Enum.reduce(
        1..length,
        {"", data},
        fn _, {chars, <<c::32, rest::binary>>} ->
          if c == 0 do
            {chars, rest}
          else
            {chars <> <<c>>, rest}
          end
        end
      )

    {name, char, rest}
    |> IO.inspect
  end

  def translate(:decode, [type, {:list, [name, _max]}], <<count::32, items::binary>>) do
    # 1..count because count includes itself, a count of 55 will include 54 total list elements
    {val, rest} =
      Enum.reduce(1..count, {[], items}, fn _, {values, rest} ->
        {_, val, rest} = translate(:decode, [type, name], rest)
        {[val | values], rest}
      end)

    {name, Enum.reverse(val), rest}
  end

  def translate(:decode, ["char", name], <<int::32, rest::binary>>), do: {name, int, rest}

  def translate(:decode, ["unsigned", "char", name], <<int::32, rest::binary>>) do
    {name, int, rest}
  end

  def translate(:encode, ["int", name], map) do
    case Map.get(map, name) do
      nil ->
        keys =
          map
          |> Map.keys()
          |> Enum.join(", ")

        throw "Key '#{name}' not found in map keys: [#{keys}]"
      val -> <<val::integer-size(32)>>
    end
  end

  def translate(:decode, ["int", name], <<int::32, rest::binary>>), do: {name, int, rest}

  def translate(:decode, ["unsigned", "short", name], <<int::32, rest::binary>>),
    do: {name, int, rest}

  def translate(:encode, ["unsigned", "int", "flags"], map) do
    case map["flags"] do
      0 ->
        <<0, 0, 0, 0, 0>>

      int when int <= 255 ->
        <<0, 0, 0, 1, int::unsigned-integer-size(8)>>

      int when int <= 65535 ->
        <<0, 0, 0, 2, int::unsigned-integer-size(16)>>

      int ->
        {:error, "unable to parse flag: #{inspect int}, ensure a valid flag is passed in with the map with a valid integer"}
    end
  end

  def translate(:encode, ["unsigned", "int", name], map) do
    int = map[name]

    if int <= 4_294_967_295 and int >= 0 do
      <<int::unsigned-integer-size(32)>>
    else
      {:error, "unsigned integer must be 32 bit and non negative: #{name}"}
    end
  end

  def translate(:decode, ["unsigned", "int", name], <<int::32, rest::binary>>),
    do: {name, int, rest}

  # hyper is a double long int
  def translate(:encode, ["unsigned", "hyper", name], map) do
    int = map[name]

    if int <= 18_446_744_073_709_551_615 and int >= 0 do
      <<int::unsigned-integer-size(64)>>
    else
      {:error, "unsigned hyper must be 64 bit and non negative: #{name}"}
    end
  end

  def translate(:decode, ["unsigned", "hyper", name], <<int::64, rest::binary>>),
    do: {name, int, rest}

  def translate(:encode, ["remote_nonnull_string", name], str),
    do: translate(:encode, ["remote_string", name], str)

  def translate(:decode, ["remote_nonnull_string", name], str),
    do: translate(:decode, ["remote_string", name], str)

  def translate(:decode, ["remote_string", name], <<0, 0, 0, 0>>), do: {name, "", <<>>}

  def translate(:encode, ["remote_string", name], map) do
    case map[name] do
      nil ->
        <<0, 0, 0, 1, 0, 0, 0, 0>>

      "" ->
        <<0, 0, 0, 1, 0, 0, 0, 0>>

      str ->
        str_size = byte_size(str)
        # there was a bug here, that 0,0,0,0 gets appended if the string is a multiple of 4 bytes
        # work around by just checking if 32 directly, but this could be cleaner
        padding = 32 - Integer.mod(bit_size(str), 32)

        if padding == 32 do
          <<str_size::32>> <> str
        else
          <<str_size::32>> <> str <> <<0::size(padding)>>
        end
    end
  end

  def translate(:decode, ["remote_string", name], <<size::32, rest::binary>>) do
    padding =
      case rem(size, 4) do
        0 -> 0
        rem -> (4 - rem) * 8
      end

    <<string::binary-size(size), _padding::size(padding), rest::binary>> = rest
    {name, string, rest}
  end

  def translate(:encode, ["remote_uuid", name], map) do
    map[name]
    |> String.to_charlist()
    |> Enum.filter(&(&1 != ?-))
    |> Enum.chunk_every(2)
    |> Enum.reduce(<<>>, fn s, acc ->
      acc <> <<String.to_integer(List.to_string(s), 16)>>
    end)
  end

  # 123e4567-e89b-12d3-a456-426614174000
  def translate(:decode, ["remote_uuid", name], <<_uuid::128, rest::binary>> = uuid) do
    <<
      a::8,
      b::8,
      c::8,
      d::8,
      e::8,
      f::8,
      g::8,
      h::8,
      i::8,
      j::8,
      k::8,
      l::8,
      m::8,
      n::8,
      o::8,
      p::8,
      _rest::binary
    >> = uuid

    parsed =
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

    {name, parsed, rest}
  end

  def translate(:encode, [name, field], payload) do
    case Libvirt.RPC.Structs.get_struct(name) do
      {:error, :notfound} ->
        {:error, "struct #{name} not found"}

      {:ok, spec} ->
        Enum.reduce(spec, <<>>, fn arg, acc ->
          acc <> translate(:encode, arg, payload[field])
        end)
    end
  end

  def translate(:decode, [name | _spec], payload) do
    case Libvirt.RPC.Structs.get_struct(name) do
      {:error, :notfound} ->
        {:error, "struct #{name} not found"}

      {:ok, val} ->
        {parsed, rest} =
          Enum.reduce(val, {%{}, payload}, fn arg, {acc, rest} ->
            {name, val, rest} = translate(:decode, arg, rest)
            {Map.merge(acc, %{name => val}), rest}
          end)

        {name, parsed, rest}
    end
  end

  def translate(:encode, unknown, _payload), do: throw("Unknown type: #{inspect(unknown)}")
  def translate(:decode, unknown, _payload), do: throw("Unknown type: #{inspect(unknown)}")
end
