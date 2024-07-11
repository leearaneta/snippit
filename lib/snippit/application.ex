defmodule Snippit.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SnippitWeb.Telemetry,
      Snippit.Repo,
      {DNSCluster, query: Application.get_env(:snippit, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Snippit.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Snippit.Finch},
      # Start a worker by calling: Snippit.Worker.start_link(arg)
      # {Snippit.Worker, arg},
      # Start to serve requests, typically the last entry
      SnippitWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Snippit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SnippitWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
