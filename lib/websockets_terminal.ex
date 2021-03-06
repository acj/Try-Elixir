defmodule WebsocketsTerminal do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(WebsocketsTerminal.Endpoint, []),
      supervisor(Registry, [:unique, WebsocketsTerminal.Registry]),
      supervisor(WebsocketsTerminal.Supervisor, []),
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    WebsocketsTerminal.Endpoint.config_change(changed, removed)
    :ok
  end
end
