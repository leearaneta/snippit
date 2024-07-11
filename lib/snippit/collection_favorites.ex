defmodule Snippit.CollectionFavorites do
  @moduledoc """
  The CollectionFavorites context.
  """

  import Ecto.Query, warn: false
  alias Snippit.Repo

  alias Snippit.CollectionFavorites.CollectionFavorite

  @doc """
  Returns the list of collection_favorites.

  ## Examples

      iex> list_collection_favorites()
      [%CollectionFavorite{}, ...]

  """
  def list_collection_favorites do
    Repo.all(CollectionFavorite)
  end

  @doc """
  Gets a single collection_favorite.

  Raises `Ecto.NoResultsError` if the Collection favorite does not exist.

  ## Examples

      iex> get_collection_favorite!(123)
      %CollectionFavorite{}

      iex> get_collection_favorite!(456)
      ** (Ecto.NoResultsError)

  """
  def get_collection_favorite!(id), do: Repo.get!(CollectionFavorite, id)

  @doc """
  Creates a collection_favorite.

  ## Examples

      iex> create_collection_favorite(%{field: value})
      {:ok, %CollectionFavorite{}}

      iex> create_collection_favorite(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_collection_favorite(attrs \\ %{}) do
    %CollectionFavorite{}
    |> CollectionFavorite.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a collection_favorite.

  ## Examples

      iex> update_collection_favorite(collection_favorite, %{field: new_value})
      {:ok, %CollectionFavorite{}}

      iex> update_collection_favorite(collection_favorite, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_collection_favorite(%CollectionFavorite{} = collection_favorite, attrs) do
    collection_favorite
    |> CollectionFavorite.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a collection_favorite.

  ## Examples

      iex> delete_collection_favorite(collection_favorite)
      {:ok, %CollectionFavorite{}}

      iex> delete_collection_favorite(collection_favorite)
      {:error, %Ecto.Changeset{}}

  """
  def delete_collection_favorite(%CollectionFavorite{} = collection_favorite) do
    Repo.delete(collection_favorite)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking collection_favorite changes.

  ## Examples

      iex> change_collection_favorite(collection_favorite)
      %Ecto.Changeset{data: %CollectionFavorite{}}

  """
  def change_collection_favorite(%CollectionFavorite{} = collection_favorite, attrs \\ %{}) do
    CollectionFavorite.changeset(collection_favorite, attrs)
  end
end
