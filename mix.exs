defmodule MockBehaviour.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mock_behaviour,
      version: "0.1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      elixir: ">= 1.4.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      name: "MockBehaviour",
      description: "Generates mocks for your behaviours",
      source_url: "https://github.com/trevoke/mock_behaviour",
      package: package(),
      deps: deps(),
      docs: [
        main: "MockBehaviour",
        source_url: "https://github.com/trevoke/mock_behaviour"
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib",]

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp package do
    [description: "Generates mocks for your behaviours",
     files: ["lib", "config", "mix.exs", "README*"],
     maintainers: ["Aldric Giacomoni"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/trevoke/mock_behaviour"}]
  end
end
