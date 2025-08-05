import Config

config :wc_logs, WcLogs.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "wc_logs_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :wc_logs, WcLogsWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_placeholder_must_be_at_least_64_bytes_long",
  server: false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime