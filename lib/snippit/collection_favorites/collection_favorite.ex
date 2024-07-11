defmodule Snippit.CollectionFavorites.CollectionFavorite do
  use Ecto.Schema
  import Ecto.Changeset

  schema "collection_favorites" do

    field :collection_id, :id
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(collection_favorite, attrs) do
    collection_favorite
    |> cast(attrs, [])
    |> validate_required([])
  end
end
