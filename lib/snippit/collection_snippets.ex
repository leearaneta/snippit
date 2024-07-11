defmodule Snippit.CollectionSnippets do
  @moduledoc """
  The CollectionSnippets context.
  """

  import Ecto.Query, warn: false
  alias Snippit.CollectionSnippets
  alias Snippit.Snippets
  alias Snippit.Repo

  alias Snippit.CollectionSnippets.CollectionSnippet

  @doc """
  Returns the list of collection_snippets.

  ## Examples

      iex> list_collection_snippets()
      [%CollectionSnippet{}, ...]

  """
  def list_collection_snippets do
    Repo.all(CollectionSnippet)
  end

  @doc """
  Gets a single collection_snippet.

  Raises `Ecto.NoResultsError` if the Collection snippet does not exist.

  ## Examples

      iex> get_collection_snippet!(123)
      %CollectionSnippet{}

      iex> get_collection_snippet!(456)
      ** (Ecto.NoResultsError)

  """
  def get_collection_snippet!(id), do: Repo.get!(CollectionSnippet, id)

  @doc """
  Creates a collection_snippet.

  ## Examples

      iex> create_collection_snippet(%{field: value})
      {:ok, %CollectionSnippet{}}

      iex> create_collection_snippet(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_collection_snippet(attrs \\ %{}) do
    %CollectionSnippet{}
    |> CollectionSnippet.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a collection_snippet.

  ## Examples

      iex> update_collection_snippet(collection_snippet, %{field: new_value})
      {:ok, %CollectionSnippet{}}

      iex> update_collection_snippet(collection_snippet, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_collection_snippet(%CollectionSnippet{} = collection_snippet, attrs) do
    collection_snippet
    |> CollectionSnippet.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a collection_snippet.

  ## Examples

      iex> delete_collection_snippet(collection_snippet)
      {:ok, %CollectionSnippet{}}

      iex> delete_collection_snippet(collection_snippet)
      {:error, %Ecto.Changeset{}}

  """
  def delete_collection_snippet(%CollectionSnippet{} = collection_snippet) do
    # load all collections
    collections = collection_snippet.snippet
      |> Ecto.assoc(:collections)
      |> Repo.all()

    if length(collections) == 1 do
      Snippets.delete_snippet(collection_snippet.snippet)
    else
      Repo.delete(collection_snippet)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking collection_snippet changes.

  ## Examples

      iex> change_collection_snippet(collection_snippet)
      %Ecto.Changeset{data: %CollectionSnippet{}}

  """
  def change_collection_snippet(%CollectionSnippet{} = collection_snippet, attrs \\ %{}) do
    CollectionSnippet.changeset(collection_snippet, attrs)
  end
end
