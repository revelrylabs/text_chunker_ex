defmodule TextChunker.MixProject do
  use Mix.Project

  @source_url "https://github.com/revelrylabs/text_chunker_ex"
  @version "0.1.0"

  def project do
    [
      app: :text_chunker,
      version: @version,
      elixir: "~> 1.15",
      deps: deps(),
      start_permanent: Mix.env() == :prod,

      source_url: @source_url,
      homepage_url: "https://github.com/revelrylabs",

      # Hex
      description: "An Elixir library for semantic text chunking.",
      package: package(),

      # Docs
      name: "TextChunker",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.10"},
      {:styler, "~> 0.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
    ]
  end

  defp docs() do
    [
      main: "readme",
      extras:
        [
          "README.md",
          "LICENSE"
        ]
    ]
  end
end
