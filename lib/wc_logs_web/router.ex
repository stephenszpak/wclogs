defmodule WcLogsWeb.Router do
  use WcLogsWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", WcLogsWeb do
    pipe_through :api

    post "/reports", ReportController, :create
    get "/reports", ReportController, :index
    get "/reports/:id", ReportController, :show
    get "/reports/:id/encounters/:encounter_id", EncounterController, :show
  end

  if Application.compile_env(:wc_logs, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: WcLogsWeb.Telemetry
    end
  end
end