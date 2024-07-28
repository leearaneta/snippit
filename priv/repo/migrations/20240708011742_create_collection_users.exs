defmodule Snippit.Repo.Migrations.CreateCollectionUsers do
  use Ecto.Migration

  def change do
    create table(:collection_users) do
      add :is_editor, :boolean, default: false, null: false
      add :collection_id, references(:collections, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:collection_users, [:collection_id])
    create index(:collection_users, [:user_id])
  end
end
