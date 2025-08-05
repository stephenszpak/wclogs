defmodule WcLogsWeb.ReportController do
  use WcLogsWeb, :controller

  alias WcLogs.Reports
  alias WcLogs.Parser

  action_fallback WcLogsWeb.FallbackController

  def index(conn, _params) do
    reports = Reports.list_reports()
    render(conn, :index, reports: reports)
  end

  def show(conn, %{"id" => id}) do
    report = Reports.get_report_with_encounters!(id)
    render(conn, :show, report: report)
  end

  def create(conn, %{"file" => upload, "uploaded_by" => uploaded_by}) do
    case handle_file_upload(upload, uploaded_by) do
      {:ok, report} ->
        conn
        |> put_status(:created)
        |> render(:show, report: Reports.get_report_with_encounters!(report.id))

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})
    end
  end

  def create(conn, %{"file" => upload}) do
    create(conn, %{"file" => upload, "uploaded_by" => "anonymous"})
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "No file provided"})
  end

  defp handle_file_upload(upload, uploaded_by) do
    case upload do
      %Plug.Upload{path: temp_path, filename: filename} ->
        if valid_log_file?(filename) do
          Parser.parse_file(temp_path, filename, uploaded_by)
        else
          {:error, "Invalid file type. Please upload a .txt combat log file."}
        end

      _ ->
        {:error, "Invalid file upload"}
    end
  end

  defp valid_log_file?(filename) do
    String.ends_with?(String.downcase(filename), [".txt", ".log"])
  end
end