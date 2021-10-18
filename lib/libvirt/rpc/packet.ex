defmodule Libvirt.RPC.Packet do
  @moduledoc false

  @enforce_keys [:program, :version, :procedure, :type, :serial, :status]
  defstruct [:size, :program, :version, :procedure, :type, :serial, :status, :payload]

  @doc """
  program - This is an arbitrarily chosen number that will uniquely identify the "service" running over the stream.

  version - This is the version number of the program, by convention starting from '1'. When an incompatible change is made to a program, the version number is incremented. Ideally both versions will then be supported on the wire in parallel for backwards compatibility.

  procedure - This is an arbitrarily chosen number that will uniquely identify the method call, or event associated with the packet. By convention, procedure numbers start from 1 and are assigned monotonically thereafter.

  type - This can be one of the following enumeration values

  * call: invocation of a method call
  * reply: completion of a method call
  * event: an asynchronous event
  * stream: control info or data from a stream

  serial - This is a number that starts from 1 and increases each time a method call packet is sent. A reply or stream packet will have a serial number matching the original method call packet serial. Events always have the serial number set to 0.

  status - This can one of the following enumeration values

  * ok: a normal packet. this is always set for method calls or events. For replies it indicates successful completion of the method. For streams it indicates confirmation of the end of file on the stream.
  * error: for replies this indicates that the method call failed and error information is being returned. For streams this indicates that not all data was sent and the stream has aborted
  * continue: for streams this indicates that further data packets will be following

  payload - Optional, raw payload data
  """
  def encode_packet(%__MODULE__{
        program: program,
        version: version,
        procedure: procedure,
        type: type,
        serial: serial,
        status: status,
        payload: nil
      }) do
    # a payload of "" will add no additional bits to the packet
    encode_packet(%__MODULE__{
      program: program,
      version: version,
      procedure: procedure,
      type: type,
      serial: serial,
      status: status,
      payload: ""
    })
  end

  def encode_packet(%__MODULE__{
        program: program,
        version: version,
        procedure: procedure,
        type: type,
        serial: serial,
        status: status,
        payload: payload
      }) do
    # (field size * num of fields) + size of payload
    size = 28 + byte_size(payload)

    <<
      size::unsigned-integer-size(32),
      program::unsigned-integer-size(32),
      version::unsigned-integer-size(32),
      procedure::signed-integer-size(32),
      type::signed-integer-size(32),
      serial::unsigned-integer-size(32),
      status::signed-integer-size(32),
      payload::binary
    >>
  end

  def decode(
        <<size::32, program::32, version::32, procedure::32, type::32, serial::32, status::32,
          payload::binary>>
      ) do
    %__MODULE__{
      size: size,
      program: program,
      version: version,
      procedure: procedure,
      type: type,
      serial: serial,
      status: status,
      payload: payload
    }
    |> decode_on_type()
  end

  def decode(
        <<size::32, program::32, version::32, procedure::32, type::32, serial::32, status::32>>
      ) do
    %__MODULE__{
      size: size,
      program: program,
      version: version,
      procedure: procedure,
      type: type,
      serial: serial,
      status: status
    }
    |> decode_on_type()
  end

  def decode(packet),
    do: {:error, "Unable to decode packet: #{inspect(packet, limit: :infinity)}"}

  def decode_on_type(%__MODULE__{status: status, payload: payload} = packet) do
    decoded_payload =
      case status do
        # ok
        0 -> {:ok, payload}
        # error
        1 -> decode_error(payload)
        # continue
        2 -> {:ok, payload}
      end

    case decoded_payload do
      {:ok, ""} -> {:ok, %__MODULE__{packet | payload: nil}}
      {:ok, payload} -> {:ok, %__MODULE__{packet | payload: payload}}
      {:error, error} -> {:error, %__MODULE__{packet | payload: error}}
    end
  end

  def decode_error(
        <<error::32, _domain::32, _::32, size::32, message::binary-size(size), _rest::binary>>
      ) do
    {error_key, _} = Libvirt.RPC.Error.vir_error_number(error)
    {:error, "#{error_key}: #{message}"}
  end
end
