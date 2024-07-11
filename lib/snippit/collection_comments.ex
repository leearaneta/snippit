defmodule Snippit.CollectionComments do
  @moduledoc """
  The CollectionComments context.
  """

  import Ecto.Query, warn: false
  alias Snippit.Repo

  alias Snippit.CollectionComments.CollectionComment

  @doc """
  Returns the list of collection_comments.

  ## Examples

      iex> list_collection_comments()
      [%CollectionComment{}, ...]

  """
  def list_collection_comments do
    Repo.all(CollectionComment)
  end

  @doc """
  Gets a single collection_comment.

  Raises `Ecto.NoResultsError` if the Collection comment does not exist.

  ## Examples

      iex> get_collection_comment!(123)
      %CollectionComment{}

      iex> get_collection_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_collection_comment!(id), do: Repo.get!(CollectionComment, id)

  @doc """
  Creates a collection_comment.

  ## Examples

      iex> create_collection_comment(%{field: value})
      {:ok, %CollectionComment{}}

      iex> create_collection_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_collection_comment(attrs \\ %{}) do
    %CollectionComment{}
    |> CollectionComment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a collection_comment.

  ## Examples

      iex> update_collection_comment(collection_comment, %{field: new_value})
      {:ok, %CollectionComment{}}

      iex> update_collection_comment(collection_comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_collection_comment(%CollectionComment{} = collection_comment, attrs) do
    collection_comment
    |> CollectionComment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a collection_comment.

  ## Examples

      iex> delete_collection_comment(collection_comment)
      {:ok, %CollectionComment{}}

      iex> delete_collection_comment(collection_comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_collection_comment(%CollectionComment{} = collection_comment) do
    Repo.delete(collection_comment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking collection_comment changes.

  ## Examples

      iex> change_collection_comment(collection_comment)
      %Ecto.Changeset{data: %CollectionComment{}}

  """
  def change_collection_comment(%CollectionComment{} = collection_comment, attrs \\ %{}) do
    CollectionComment.changeset(collection_comment, attrs)
  end
end
