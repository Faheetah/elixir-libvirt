# Handling streaming

Really need to provide everything for the TCP server to finish its job.

# A note on streaming

The order of packets while streaming in is a standard null packet (status 0 type 10 followed by a stream, which is an alternating pattern of a packet with a payload (max size seems to be 262148) and either a packet with a size of 52 with a payload of 24 zeroes, or a packet with a size of 28 with a nil payload, with the payload being the only differentation between the two. The status is still 2 and type is still 3. The only way to tell that the stream has ended is to check the payload after receiving data to see if the payload is nil (no further data for a given serial) or 24 bytes of zeroes (further data incoming).

```
%Libvirt.RPC.Packet{
  payload: nil,
  procedure: 209,
  program: 536903814,
  serial: 2,
  size: 28,
  status: 0,
  type: 1,
  version: 1
}
%Libvirt.RPC.Packet{
  payload: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, ...>>,
  procedure: 209,
  program: 536903814,
  serial: 2,
  size: 262148,
  status: 2,
  type: 3,
  version: 1
}
%Libvirt.RPC.Packet{
  payload: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0>>,
  procedure: 209,
  program: 536903814,
  serial: 2,
  size: 52,
  status: 2,
  type: 3,
  version: 1
}
%Libvirt.RPC.Packet{
  payload: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, ...>>,
  procedure: 209,
  program: 536903814,
  serial: 2,
  size: 112668,
  status: 2,
  type: 3,
  version: 1
}
%Libvirt.RPC.Packet{
  payload: nil,
  procedure: 209,
  program: 536903814,
  serial: 2,
  size: 28,
  status: 2,
  type: 3,
  version: 1
}
```
