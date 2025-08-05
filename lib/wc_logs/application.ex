defmodule WcLogs.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WcLogs.Repo,
      {DNSCluster, query: Application.get_env(:wc_logs, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: WcLogs.PubSub},
      {Finch, name: WcLogs.Finch},
      WcLogsWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: WcLogs.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    WcLogsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end