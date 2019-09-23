defmodule Enmity.MixProject do
  use Mix.Project

  def project do
    [
      app: :enmity,
      version: "0.2.0",
      description: "A Discord library.",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      source_url: "https://github.com/Cantido/enmity",
      test_paths: test_paths(Mix.env())
    ]
  end

  defp test_paths(:integration), do: ["test/integration"]
  defp test_paths(_), do: ["test/unit"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 1.5"},
      {:poison, "~> 3.1"},
      {:ex_doc, "~> 0.21", only: :dev}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Rosa Richter"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/Cantido/enmity"},
    ]
  end
end
