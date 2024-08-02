defmodule Snippit.Repo.Migrations.CreateSnippetFavorites do
  use Ecto.Migration

  def change do
    create table(:snippet_favorites) do
      add :snippet_id, references(:snippets, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:snippet_favorites, [:snippet_id])
    create index(:snippet_favorites, [:user_id])
  end
end
