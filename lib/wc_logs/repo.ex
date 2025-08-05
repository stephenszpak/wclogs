defmodule WcLogs.Repo do
  use Ecto.Repo,
    otp_app: :wc_logs,
    adapter: Ecto.Adapters.Postgres
end