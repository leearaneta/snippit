defmodule Snippit.Repo.Migrations.CreateSnippets do
  use Ecto.Migration

  def change do
    create table(:snippets) do
      add :spotify_url, :string, null: false
      add :start_ms, :integer, null: false
      add :end_ms, :integer, null: false
      add :duration_ms, :integer, null: false
      add :track, :string, null: false
      add :artist, :string, null: false
      add :album, :string, null: false
      add :thumbnail_url, :string, null: false
      add :image_url, :string, null: false
      add :created_by_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:snippets, [:created_by_id])
    create index(:snippets, [:spotify_url])

  end
end
