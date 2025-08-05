defmodule WcLogsWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("wc_logs.repo.query.total_time",
        unit: {:native, :millisecond}
      ),
      counter("wc_logs.repo.query.count"),
      counter("phoenix.endpoint.stop.count"),
      counter("phoenix.router_dispatch.stop.count")
    ]
  end

  defp periodic_measurements do
    [
      {WcLogs, :measure_users, []},
      {:process_info,
       event: [:wc_logs, :application], name: WcLogs.Application,
       keys: [:message_queue_len, :memory]}
    ]
  end
end