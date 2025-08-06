import Config

config :wc_logs, WcLogs.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "wc_logs_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :wc_logs, WcLogsWeb.Endpoint,
  http: [
    ip: {0, 0, 0, 0}, 
    port: 4001,
    protocol_options: [
      max_body_length: 1_000_000_000,
      request_timeout: 120_000
    ]
  ],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "development_secret_key_base_placeholder_must_be_at_least_64_bytes",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ]

config :wc_logs, WcLogsWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/wc_logs_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

config :wc_logs, dev_routes: true

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime