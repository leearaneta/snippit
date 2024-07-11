defmodule Snippit.Repo.Migrations.CreateCollectionFavorites do
  use Ecto.Migration

  def change do
    create table(:collection_favorites) do
      add :collection_id, references(:collections, on_delete: :nothing), null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:collection_favorites, [:collection_id])
    create index(:collection_favorites, [:user_id])
  end
end
