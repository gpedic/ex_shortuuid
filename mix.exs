defmodule ShortUUID.Mixfile do
  use Mix.Project

  @name "ShortUUID"
  @version "4.1.0"
  @url "https://github.com/gpedic/ex_shortuuid"

  def project do
    [
      app: :shortuuid,
      name: @name,
      version: @version,
      elixir: "~> 1.4",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ],
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
      {:elixir_uuid, "~> 1.2", only: :test},
      {:stream_data, "~> 0.5", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:benchee, "~> 1.3", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
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
