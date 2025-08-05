defmodule WcLogs.Reports do
  @moduledoc """
  The Reports context.
  """

  import Ecto.Query, warn: false
  alias WcLogs.Repo

  alias WcLogs.Reports.{Report, Encounter, Participant}

  @doc """
  Returns the list of reports.
  """
  def list_reports do
    Repo.all(Report)
  end

  @doc """
  Gets a single report.
  """
  def get_report!(id), do: Repo.get!(Report, id)

  @doc """
  Gets a report with encounters preloaded.
  """
  def get_report_with_encounters!(id) do
    Repo.get!(Report, id)
    |> Repo.preload(:encounters)
  end

  @doc """
  Creates a report.
  """
  def create_report(attrs \\ %{}) do
    %Report{}
    |> Report.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets an encounter with participants.
  """
  def get_encounter_with_participants!(id) do
    Repo.get!(Encounter, id)
    |> Repo.preload(:participants)
  end

  @doc """
  Creates an encounter.
  """
  def create_encounter(attrs \\ %{}) do
    %Encounter{}
    |> Encounter.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a participant.
  """
  def create_participant(attrs \\ %{}) do
    %Participant{}
    |> Participant.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates multiple participants.
  """
  def create_participants(participants_data) do
    Repo.insert_all(Participant, participants_data, returning: true)
  end
end