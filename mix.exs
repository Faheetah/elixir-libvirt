defmodule Libvirt.MixProject do
  use Mix.Project

  def project do
    [
      app: :libvirt,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets, :crypto],
      mod: {Libvirt.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_parsec, "~> 1.1", runetime: false},
      {:certifi, ">= 2.7.0", runetime: false},
      {:benchee, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.24.2", only: [:dev], runtime: false},
      {:credo, "~> 1.5", only: [:dev], runtime: false}
    ]
  end

  def docs do
    [
      formatters: ["html"],
      extras: ["README.md"]
    ]
  end
end
