defmodule Snippit.SnippetFavorites.SnippetFavorite do
  use Ecto.Schema
  import Ecto.Changeset

  schema "snippet_favorites" do

    field :snippet_id, :id
    field :user_id, :id
    field :from_collection_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(snippet_favorite, attrs) do
    snippet_favorite
    |> cast(attrs, [])
    |> validate_required([])
  end
end
