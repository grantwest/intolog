defmodule IntoLog.MixProject do
  use Mix.Project

  @version "1.0.0"
  @description "Collectable for Logger"

  def project do
    [
      app: :into_log,
      version: @version,
      elixir: "~> 1.11",
      deps: deps(),
      package: package(),
      description: @description,
      name: "IntoLog",
      xref: [],
      consolidate_protocols: Mix.env() != :test,
      docs: [
        source_ref: "v#{@version}",
        source_url: "https://github.com/grantwest/intolog"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      maintainers: ["Grant West"],
      links: %{"GitHub" => "https://github.com/grantwest/intolog"},
      files: ["lib", "mix.exs", "README.md", "LICENSE", "src"]
    }
  end
end
