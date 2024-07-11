defmodule Snippit.CollectionSnippetComments do
  @moduledoc """
  The CollectionSnippetComments context.
  """

  import Ecto.Query, warn: false
  alias Snippit.Repo

  alias Snippit.CollectionSnippetComments.CollectionSnippetComment

  @doc """
  Returns the list of collection_snippet_comments.

  ## Examples

      iex> list_collection_snippet_comments()
      [%CollectionSnippetComment{}, ...]

  """
  def list_collection_snippet_comments do
    Repo.all(CollectionSnippetComment)
  end

  @doc """
  Gets a single collection_snippet_comment.

  Raises `Ecto.NoResultsError` if the Collection snippet comment does not exist.

  ## Examples

      iex> get_collection_snippet_comment!(123)
      %CollectionSnippetComment{}

      iex> get_collection_snippet_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_collection_snippet_comment!(id), do: Repo.get!(CollectionSnippetComment, id)

  @doc """
  Creates a collection_snippet_comment.

  ## Examples

      iex> create_collection_snippet_comment(%{field: value})
      {:ok, %CollectionSnippetComment{}}

      iex> create_collection_snippet_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_collection_snippet_comment(attrs \\ %{}) do
    %CollectionSnippetComment{}
    |> CollectionSnippetComment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a collection_snippet_comment.

  ## Examples

      iex> update_collection_snippet_comment(collection_snippet_comment, %{field: new_value})
      {:ok, %CollectionSnippetComment{}}

      iex> update_collection_snippet_comment(collection_snippet_comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_collection_snippet_comment(%CollectionSnippetComment{} = collection_snippet_comment, attrs) do
    collection_snippet_comment
    |> CollectionSnippetComment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a collection_snippet_comment.

  ## Examples

      iex> delete_collection_snippet_comment(collection_snippet_comment)
      {:ok, %CollectionSnippetComment{}}

      iex> delete_collection_snippet_comment(collection_snippet_comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_collection_snippet_comment(%CollectionSnippetComment{} = collection_snippet_comment) do
    Repo.delete(collection_snippet_comment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking collection_snippet_comment changes.

  ## Examples

      iex> change_collection_snippet_comment(collection_snippet_comment)
      %Ecto.Changeset{data: %CollectionSnippetComment{}}

  """
  def change_collection_snippet_comment(%CollectionSnippetComment{} = collection_snippet_comment, attrs \\ %{}) do
    CollectionSnippetComment.changeset(collection_snippet_comment, attrs)
  end
end
