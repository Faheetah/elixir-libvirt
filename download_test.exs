# Setup filesystem

File.rm_rf!("images/")
File.mkdir_p!("images/pool/")

file_contents = Enum.reduce(1..1000, "", fn _, acc -> acc <> "." end)
File.write("images/original.img", file_contents)


# Connect

IO.puts "connecting..."
conn = Libvirt.connect!("localhost")


# Clean up old references
case Libvirt.Pool.get_by_name(conn, "test") do
  {:ok, %{"remote_nonnull_storage_pool" => test_pool}} ->
    case Libvirt.Volume.lookup_by_name(conn, test_pool, "test") do
      {:ok, %{"remote_nonnull_storage_vol" => volume}} ->
        Libvirt.Volume.delete(conn, volume)
      _ -> IO.puts "test volume already deleted"
    end

    Libvirt.Pool.destroy(conn, test_pool)
    Libvirt.Pool.undefine(conn, test_pool)

    IO.puts "deleted test pool"

  _ -> IO.puts "test pool already deleted"
end


# Create the pool and volume

IO.puts "creating pool"

test_pool =
  Libvirt.Pool.create(
    conn,
    %{"name" => "test", "uuid" => Libvirt.UUID.gen_string()},
    "images/pool/"
  )

IO.puts "creating volume"

test_volume_params = %Libvirt.Volume{name: "test", pool: "test", path: "test.img", capacity: 1, unit: "M"}
{:ok, _} = Libvirt.Volume.create(conn, test_volume_params)


# Upload the file
IO.puts "uploading volume"

Libvirt.Volume.upload(conn, test_volume_params, file: "images/original.img")


# Download the file

IO.puts "downloading file"

# This gets very spammy
Logger.configure(level: :info)
Libvirt.Volume.download(
  conn,
  %{
    "key" => "/home/main/libvirt/test/test.img",
    "name" => "test",
    "pool" => "test"
  },
  file: "images/downloaded.img"
)
Logger.configure(level: :debug)

IO.puts "done"
