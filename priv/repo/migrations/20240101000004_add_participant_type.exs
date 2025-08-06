defmodule WcLogs.Repo.Migrations.AddParticipantType do
  use Ecto.Migration

  def change do
    alter table(:participants) do
      add :participant_type, :string, default: "player"
    end
  end
end