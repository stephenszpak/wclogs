defmodule WcLogsWeb.PageController do
  use WcLogsWeb, :controller

  def index(conn, _params) do
    static_path = Path.join([Application.app_dir(:wc_logs, "priv/static"), "index.html"])
    
    case File.read(static_path) do
      {:ok, content} ->
        conn
        |> put_resp_header("content-type", "text/html; charset=utf-8")
        |> send_resp(200, content)
      
      {:error, _} ->
        # Fallback HTML if React build not found
        html_content = """
        <!DOCTYPE html>
        <html>
        <head>
          <title>WC Logs</title>
          <style>
            body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
            .container { max-width: 600px; margin: 0 auto; }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>WC Logs - Combat Log Analyzer</h1>
            <p>Welcome to WC Logs! This is a World of Warcraft combat log analyzer.</p>
            <p><strong>API is running at:</strong> <a href="/api/reports">/api/reports</a></p>
            <p>Upload combat logs via POST to /api/reports</p>
          </div>
        </body>
        </html>
        """
        
        conn
        |> put_resp_header("content-type", "text/html; charset=utf-8")
        |> send_resp(200, html_content)
    end
  end
end