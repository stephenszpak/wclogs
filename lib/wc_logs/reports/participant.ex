defmodule WcLogs.Reports.Participant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "participants" do
    field :guid, :string
    field :name, :string
    field :class, :string
    field :spec, :string
    field :participant_type, :string, default: "player"
    field :total_damage_done, :integer, default: 0
    field :total_healing_done, :integer, default: 0
    field :total_damage_taken, :integer, default: 0
    field :dps, :float, default: 0.0
    field :hps, :float, default: 0.0
    field :deaths, :integer, default: 0
    field :item_level, :integer

    belongs_to :encounter, WcLogs.Reports.Encounter

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:guid, :name, :class, :spec, :participant_type, :total_damage_done, :total_healing_done, 
                    :total_damage_taken, :dps, :hps, :deaths, :item_level, :encounter_id])
    |> validate_required([:guid, :name, :encounter_id])
  end
end