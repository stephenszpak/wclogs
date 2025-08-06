import Config

if System.get_env("PHX_SERVER") do
  config :wc_logs, WcLogsWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :wc_logs, WcLogs.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :wc_logs, WcLogsWeb.Endpoint,
    url: [host: host, port: port, scheme: "http"],
    http: [
      ip: {0, 0, 0, 0},
      port: port,
      protocol_options: [
        max_request_line_length: 8192,
        max_header_name_length: 64,
        max_header_value_length: 4096,
        max_headers: 100,
        max_body_length: 1_000_000_000,
        request_timeout: 120_000
      ]
    ],
    secret_key_base: secret_key_base
end