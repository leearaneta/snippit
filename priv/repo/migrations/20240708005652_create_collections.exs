defmodule Snippit.Repo.Migrations.CreateCollections do
  use Ecto.Migration

  def change do
    create table(:collections) do
      add :name, :string, null: false
      add :description, :string
      add :is_private, :boolean, default: false, null: false
      add :created_by_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:collections, [:created_by_id])
  end
end
