defmodule WcLogsWeb.Router do
  use WcLogsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

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

  scope "/", WcLogsWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/*path", PageController, :index
  end

  if Application.compile_env(:wc_logs, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: WcLogsWeb.Telemetry
    end
  end
end