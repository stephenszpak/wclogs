defmodule WcLogsWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :wc_logs

  @session_options [
    store: :cookie,
    key: "_wc_logs_key",
    signing_salt: "wc_logs_salt",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  plug Plug.Static,
    at: "/",
    from: :wc_logs,
    gzip: false,
    only: WcLogsWeb.static_paths()

  plug Plug.Static,
    at: "/static",
    from: {:wc_logs, "priv/static"},
    gzip: false

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :wc_logs
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library(),
    length: 1_000_000_000,
    read_length: 1_000_000_000,
    read_timeout: 120_000

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  
  plug CORSPlug,
    origin: ["http://localhost:3000", "http://localhost:4001"],
    max_age: 86400,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]

  plug WcLogsWeb.Router
end