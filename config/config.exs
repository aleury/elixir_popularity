import Config

config :elixir_popularity, ecto_repos: [ElixirPopularity.Repo]

config :elixir_popularity, ElixirPopularity.Repo,
  database: "elixir_popularity_dev",
  username: "guest",
  password: "guest",
  hostname: "localhost"

config :logger, :console, format: "[$level] $message\n"
