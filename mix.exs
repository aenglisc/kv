defmodule Kv.MixProject do
  use Mix.Project

  def project do
    [
      app: :kv,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Kv.Application, []}
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:plug,        "~> 1.7"},
    ]
  end
end
