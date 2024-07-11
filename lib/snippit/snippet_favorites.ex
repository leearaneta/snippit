defmodule Snippit.SnippetFavorites do
  @moduledoc """
  The SnippetFavorites context.
  """

  import Ecto.Query, warn: false
  alias Snippit.Repo

  alias Snippit.SnippetFavorites.SnippetFavorite

  @doc """
  Returns the list of snippet_favorites.

  ## Examples

      iex> list_snippet_favorites()
      [%SnippetFavorite{}, ...]

  """
  def list_snippet_favorites do
    Repo.all(SnippetFavorite)
  end

  @doc """
  Gets a single snippet_favorite.

  Raises `Ecto.NoResultsError` if the Snippet favorite does not exist.

  ## Examples

      iex> get_snippet_favorite!(123)
      %SnippetFavorite{}

      iex> get_snippet_favorite!(456)
      ** (Ecto.NoResultsError)

  """
  def get_snippet_favorite!(id), do: Repo.get!(SnippetFavorite, id)

  @doc """
  Creates a snippet_favorite.

  ## Examples

      iex> create_snippet_favorite(%{field: value})
      {:ok, %SnippetFavorite{}}

      iex> create_snippet_favorite(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_snippet_favorite(attrs \\ %{}) do
    %SnippetFavorite{}
    |> SnippetFavorite.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a snippet_favorite.

  ## Examples

      iex> update_snippet_favorite(snippet_favorite, %{field: new_value})
      {:ok, %SnippetFavorite{}}

      iex> update_snippet_favorite(snippet_favorite, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_snippet_favorite(%SnippetFavorite{} = snippet_favorite, attrs) do
    snippet_favorite
    |> SnippetFavorite.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a snippet_favorite.

  ## Examples

      iex> delete_snippet_favorite(snippet_favorite)
      {:ok, %SnippetFavorite{}}

      iex> delete_snippet_favorite(snippet_favorite)
      {:error, %Ecto.Changeset{}}

  """
  def delete_snippet_favorite(%SnippetFavorite{} = snippet_favorite) do
    Repo.delete(snippet_favorite)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking snippet_favorite changes.

  ## Examples

      iex> change_snippet_favorite(snippet_favorite)
      %Ecto.Changeset{data: %SnippetFavorite{}}

  """
  def change_snippet_favorite(%SnippetFavorite{} = snippet_favorite, attrs \\ %{}) do
    SnippetFavorite.changeset(snippet_favorite, attrs)
  end
end
