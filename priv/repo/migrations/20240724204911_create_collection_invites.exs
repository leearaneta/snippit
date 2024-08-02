defmodule Snippit.Repo.Migrations.CreateCollectionInvites do
  use Ecto.Migration

  def change do
    create table(:collection_invites) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :from_user_id, references(:users, on_delete: :delete_all), null: false
      add :collection_id, references(:collections, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:collection_invites, [:user_id])
    create index(:collection_invites, [:from_user_id])
    create index(:collection_invites, [:collection_id])
    create index(:collection_invites, [:user_id, :collection_id], unique: true)
  end
end
