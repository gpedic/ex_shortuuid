defmodule ShortUUID.Mixfile do
  use Mix.Project

  def project do
    [app: :shortuuid,
     name: "ShortUUID",
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package(),
     description: description(),
     docs: [main: ShortUUID],
     deps: deps()]
  end

  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
    ]
  end

  defp description do
    """
    ShortUUID is a simple UUID shortener library.
    """
  end

  defp package do
    # These are the default files included in the package
    [
      name: :shortuuid,
      files: ["lib" , "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
      maintainers: ["Goran Pedić"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/gpedic/shortuuid"}
    ]
  end
end
