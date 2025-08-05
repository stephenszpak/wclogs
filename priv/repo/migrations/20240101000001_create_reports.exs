defmodule WcLogs.Repo.Migrations.CreateReports do
  use Ecto.Migration

  def change do
    create table(:reports) do
      add :filename, :string, null: false
      add :uploaded_by, :string
      add :start_time, :utc_datetime
      add :end_time, :utc_datetime
      add :zone_name, :string

      timestamps(type: :utc_datetime)
    end

    create index(:reports, [:uploaded_by])
    create index(:reports, [:start_time])
  end
end