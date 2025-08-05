defmodule WcLogs.Repo.Migrations.CreateParticipants do
  use Ecto.Migration

  def change do
    create table(:participants) do
      add :guid, :string, null: false
      add :name, :string, null: false
      add :class, :string
      add :spec, :string
      add :total_damage_done, :bigint, default: 0
      add :total_healing_done, :bigint, default: 0
      add :total_damage_taken, :bigint, default: 0
      add :dps, :float, default: 0.0
      add :hps, :float, default: 0.0
      add :deaths, :integer, default: 0
      add :item_level, :integer
      add :encounter_id, references(:encounters, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:participants, [:encounter_id])
    create index(:participants, [:guid])
    create index(:participants, [:name])
    create index(:participants, [:total_damage_done])
    create index(:participants, [:total_healing_done])
  end
end