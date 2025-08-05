defmodule WcLogsWeb.EncounterController do
  use WcLogsWeb, :controller

  alias WcLogs.Reports

  action_fallback WcLogsWeb.FallbackController

  def show(conn, %{"id" => _report_id, "encounter_id" => encounter_id}) do
    encounter = Reports.get_encounter_with_participants!(encounter_id)
    render(conn, :show, encounter: encounter)
  end
end