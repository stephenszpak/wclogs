defmodule WcLogsWeb.ReportJSON do
  alias WcLogs.Reports.Report

  @doc """
  Renders a list of reports.
  """
  def index(%{reports: reports}) do
    %{data: for(report <- reports, do: data(report))}
  end

  @doc """
  Renders a single report.
  """
  def show(%{report: report}) do
    %{data: data(report)}
  end

  defp data(%Report{} = report) do
    %{
      id: report.id,
      filename: report.filename,
      uploaded_by: report.uploaded_by,
      start_time: report.start_time,
      end_time: report.end_time,
      zone_name: report.zone_name,
      encounters: render_encounters(report.encounters || [])
    }
  end

  defp render_encounters(encounters) when is_list(encounters) do
    Enum.map(encounters, &render_encounter/1)
  end

  defp render_encounters(_), do: []

  defp render_encounter(encounter) do
    %{
      id: encounter.id,
      encounter_id: encounter.encounter_id,
      boss_name: encounter.boss_name,
      start_time: encounter.start_time,
      end_time: encounter.end_time,
      duration_ms: encounter.duration_ms,
      success: encounter.success,
      zone_name: encounter.zone_name,
      difficulty: encounter.difficulty
    }
  end
end