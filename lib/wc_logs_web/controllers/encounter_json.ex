defmodule WcLogsWeb.EncounterJSON do
  alias WcLogs.Reports.Encounter

  @doc """
  Renders a single encounter with participants.
  """
  def show(%{encounter: encounter}) do
    %{data: data(encounter)}
  end

  defp data(%Encounter{} = encounter) do
    %{
      id: encounter.id,
      encounter_id: encounter.encounter_id,
      boss_name: encounter.boss_name,
      start_time: encounter.start_time,
      end_time: encounter.end_time,
      duration_ms: encounter.duration_ms,
      success: encounter.success,
      zone_name: encounter.zone_name,
      difficulty: encounter.difficulty,
      participants: render_participants(encounter.participants || [])
    }
  end

  defp render_participants(participants) when is_list(participants) do
    damage_dealers = participants
    |> Enum.filter(&(&1.total_damage_done > 0))
    |> Enum.sort_by(&(&1.total_damage_done), :desc)

    healers = participants
    |> Enum.filter(&(&1.total_healing_done > 0))
    |> Enum.sort_by(&(&1.total_healing_done), :desc)

    %{
      damage: Enum.map(damage_dealers, &render_participant/1),
      healing: Enum.map(healers, &render_participant/1),
      all: Enum.map(participants, &render_participant/1)
    }
  end

  defp render_participants(_), do: %{damage: [], healing: [], all: []}

  defp render_participant(participant) do
    %{
      id: participant.id,
      guid: participant.guid,
      name: participant.name,
      class: participant.class,
      spec: participant.spec,
      total_damage_done: participant.total_damage_done,
      total_healing_done: participant.total_healing_done,
      total_damage_taken: participant.total_damage_taken,
      dps: participant.dps,
      hps: participant.hps,
      deaths: participant.deaths,
      item_level: participant.item_level
    }
  end
end