defmodule TextChunker.MixProject do
  use Mix.Project

  def project do
    [
      app: :text_chunker,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Docs
      name: "TextChunker",
      source_url: "https://github.com/revelrylabs/text_chunker_ex",
      homepage_url: "https://github.com/revelrylabs",
      docs: [
        main: "TextChunker", # The main page in the docs
        extras: ["README.md"]
      ]
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
end
