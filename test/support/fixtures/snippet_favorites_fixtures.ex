defmodule Snippit.SnippetFavoritesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Snippit.SnippetFavorites` context.
  """

  @doc """
  Generate a snippet_favorite.
  """
  def snippet_favorite_fixture(attrs \\ %{}) do
    {:ok, snippet_favorite} =
      attrs
      |> Enum.into(%{

      })
      |> Snippit.SnippetFavorites.create_snippet_favorite()

    snippet_favorite
  end
end
