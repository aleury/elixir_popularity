defmodule ElixirPopularity.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      :hackney_pool.child_spec(:hn_id_pool, timeout: 15_000, max_connections: 100),
      ElixirPopularity.Repo,
      ElixirPopularity.RMQPublisher,
      ElixirPopularity.HackerNewsItemIdProducer,
      ElixirPopularity.HackerNewsItemIdProcessor,
      ElixirPopularity.HackerNewsItemProcessor
      # Starts a worker by calling: ElixirPopularity.Worker.start_link(arg)
      # {ElixirPopularity.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirPopularity.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
