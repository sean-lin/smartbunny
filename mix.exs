defmodule SmartBunny.Mixfile do
  use Mix.Project

  def project do
    [app: :smart_bunny,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      mod: { SmartBunny, []},
      applications: [
        :logger,
        :logger_file_backend,
        :inets,
        :ssl,
        :crypto,
        :tunctl,
      ]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:logger_file_backend, github: "sean-lin/logger_file_backend"},
      {:tunctl, github: "msantos/tunctl"},
      {:exrm, "~> 0.18.1"},
    ]
  end
end
