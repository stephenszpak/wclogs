defmodule WcLogs.Repo.Migrations.CreateEncounters do
  use Ecto.Migration

  def change do
    create table(:encounters) do
      add :encounter_id, :integer, null: false
      add :boss_name, :string, null: false
      add :start_time, :utc_datetime, null: false
      add :end_time, :utc_datetime
      add :duration_ms, :integer
      add :success, :boolean, default: false
      add :zone_name, :string
      add :difficulty, :string
      add :report_id, references(:reports, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:encounters, [:report_id])
    create index(:encounters, [:encounter_id])
    create index(:encounters, [:boss_name])
  end
end