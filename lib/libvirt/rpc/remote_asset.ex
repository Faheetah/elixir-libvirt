defmodule Libvirt.RPC.RemoteAsset do
  @moduledoc """
  Fetches a remote Libvirt asset from the internet, using the
  specified version and file.

  i.e. https://gitlab.com/libvirt/libvirt/-/raw/v6.0.0/include/libvirt/virterror.h
  """

  def fetch(version, path) do
    cache_path = Path.join(["_build", "libvirt_assets", version, path])

    if File.exists?(cache_path) do
      File.read!(cache_path)
    else
      File.mkdir_p!(Path.dirname(cache_path))

      url = Path.join([
        "https://gitlab.com/libvirt/libvirt/-/raw/v#{version}",
        path
      ])

      sslOpts = [verify: :verify_peer, cacertfile: :certifi.cacertfile()]

      :inets.start()
      {:ok, {{_, 200, 'OK'}, _, body}} = :httpc.request(:get, {url, []}, [ssl: sslOpts], [])

      body = to_string(body)
      File.write!(cache_path, body)
      body
    end
  end
end
