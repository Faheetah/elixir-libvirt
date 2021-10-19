defmodule Libvirt.RPC.Translation do
  @moduledoc "Generate functions for proc ID to proc names"

  require Libvirt.RPC.TranslationGenerator
  Libvirt.RPC.TranslationGenerator.generate("6.0.0")
end
