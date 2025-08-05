defmodule WcLogs.Reports.Encounter do
  use Ecto.Schema
  import Ecto.Changeset

  schema "encounters" do
    field :encounter_id, :integer
    field :boss_name, :string
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    field :duration_ms, :integer
    field :success, :boolean, default: false
    field :zone_name, :string
    field :difficulty, :string

    belongs_to :report, WcLogs.Reports.Report
    has_many :participants, WcLogs.Reports.Participant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(encounter, attrs) do
    encounter
    |> cast(attrs, [:encounter_id, :boss_name, :start_time, :end_time, :duration_ms, :success, :zone_name, :difficulty, :report_id])
    |> validate_required([:encounter_id, :boss_name, :start_time, :report_id])
  end
end