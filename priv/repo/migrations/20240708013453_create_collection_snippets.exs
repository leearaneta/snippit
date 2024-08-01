defmodule Snippit.Repo.Migrations.CreateCollectionSnippets do
  use Ecto.Migration

  def change do
    create table(:collection_snippets) do
      add :index, :integer, default: 0
      add :description, :string
      add :collection_id, references(:collections, on_delete: :delete_all), null: false
      add :from_collection_id, references(:collections, on_delete: :nilify_all)
      add :snippet_id, references(:snippets, on_delete: :delete_all), null: false
      add :added_by_id, references(:users, on_delete: :nilify_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:collection_snippets, [:collection_id])
    create index(:collection_snippets, [:from_collection_id])
    create index(:collection_snippets, [:snippet_id])
    create index(:collection_snippets, [:added_by_id])
    create index(:collection_snippets, [:collection_id, :snippet_id], unique: true)
  end
end
