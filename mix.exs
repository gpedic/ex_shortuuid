defmodule ShortUUID.Mixfile do
  use Mix.Project

  @name "ShortUUID"
  @version "2.1.2"
  @url "https://github.com/gpedic/ex_shortuuid"

  def project do
    [
      app: :shortuuid,
      name: @name,
      version: @version,
      elixir: "~> 1.4",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      aliases: aliases(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  def application do
    [extra_applications: []]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, ">= 0.7.0", only: :test},
      {:benchee, "~> 0.14", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false}
    ]
  end

  defp aliases do
    [
      "bench.encode": ["run bench/encode.exs"],
      "bench.decode": ["run bench/decode.exs"]
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @url,
      formatters: ["html"]
    ]
  end

  defp package do
    # These are the default files included in the package
    [
      name: :shortuuid,
      description: "ShortUUID - generate concise, unambiguous, URL-safe UUIDs",
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Goran Pedić"],
      licenses: ["MIT"],
      links: %{"GitHub" => @url}
    ]
  end
end
