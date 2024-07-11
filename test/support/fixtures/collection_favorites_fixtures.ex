defmodule Snippit.CollectionFavoritesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Snippit.CollectionFavorites` context.
  """

  @doc """
  Generate a collection_favorite.
  """
  def collection_favorite_fixture(attrs \\ %{}) do
    {:ok, collection_favorite} =
      attrs
      |> Enum.into(%{

      })
      |> Snippit.CollectionFavorites.create_collection_favorite()

    collection_favorite
  end
end
