defmodule Snippit.Repo.Migrations.CreateCollectionComments do
  use Ecto.Migration

  def change do
    create table(:collection_comments) do
      add :comment, :string, null: false
      add :collection_id, references(:collections, on_delete: :nothing), null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:collection_comments, [:collection_id])
    create index(:collection_comments, [:user_id])
  end
end
