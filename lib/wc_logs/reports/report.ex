defmodule WcLogs.Reports.Report do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reports" do
    field :filename, :string
    field :uploaded_by, :string
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    field :zone_name, :string

    has_many :encounters, WcLogs.Reports.Encounter

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [:filename, :uploaded_by, :start_time, :end_time, :zone_name])
    |> validate_required([:filename])
  end
end