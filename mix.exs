defmodule ShortUUID.Mixfile do
  use Mix.Project

  @name "ShortUUID"
  @version "2.1.0"
  @url "https://github.com/gpedic/ex_shortuuid"

  def project do
    [app: :shortuuid,
     name: @name,
     version: @version,
     elixir: "~> 1.4",
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [coveralls: :test],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package(),
     description: description(),
     docs: docs(),
     deps: deps()]
  end

  def application do
    [extra_applications: []]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.14.0", only: :dev, runtime: false},
      {:excoveralls, ">= 0.7.0", only: :test}
    ]
  end

  defp docs() do
    [
      main: @name,
      source_ref: "v#{@version}",
      source_url: @url,
      extras: [
        "README.md"
      ]
    ]
  end

  defp description do
    """
    ShortUUID - generate concise, unambiguous, URL-safe UUIDs
    """
  end

  defp package do
    # These are the default files included in the package
    [
      name: :shortuuid,
      files: ["lib" , "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Goran Pedić"],
      licenses: ["MIT"],
      links: %{"GitHub" => @url}
    ]
  end
end
