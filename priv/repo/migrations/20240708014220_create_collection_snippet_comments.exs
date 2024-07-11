defmodule Snippit.Repo.Migrations.CreateCollectionSnippetComments do
  use Ecto.Migration

  def change do
    create table(:collection_snippet_comments) do
      add :comment, :string, null: false
      add :collection_snippet_id, references(:collection_snippets, on_delete: :nothing), null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:collection_snippet_comments, [:collection_snippet_id])
    create index(:collection_snippet_comments, [:user_id])
  end
end
