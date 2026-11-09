defmodule ShortUUID.Mixfile do
  use Mix.Project

  @name "ShortUUID"
  @version "4.3.0"
  @url "https://github.com/gpedic/ex_shortuuid"

  def project do
    [
      app: :shortuuid,
      name: @name,
      version: @version,
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      aliases: aliases(),
      start_permanent: Mix.env() == :prod,
      package: package(),
      docs: docs(),
      dialyzer: [plt_local_path: "priv/plts", plt_core_path: "priv/plts"],
      deps: deps()
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.github": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [extra_applications: []]
  end

  defp deps do
    [
      {:elixir_uuid, "~> 1.2", only: :test},
      {:stream_data, "~> 1.0", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:benchee, "~> 1.3", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: :dev, runtime: false},
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
      formatters: ["html", "markdown"]
    ]
  end

  defp package do
    # These are the default files included in the package
    [
      name: :shortuuid,
      description:
        "ShortUUID - encode UUIDs as concise, unambiguous strings, URL-safe by default, with predefined and custom alphabets",
      files: ["lib", "mix.exs", "README*", "LICENSE*", "CHANGELOG*", "usage-rules.md"],
      maintainers: ["Goran Pedić"],
      licenses: ["MIT"],
      links: %{"GitHub" => @url, "Changelog" => "#{@url}/blob/master/CHANGELOG.md"}
    ]
  end
end
