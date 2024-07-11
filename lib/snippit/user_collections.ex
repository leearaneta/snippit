defmodule Snippit.CollectionUsers do
  @moduledoc """
  The CollectionUsers context.
  """

  import Ecto.Query, warn: false
  alias Snippit.Repo

  alias Snippit.CollectionUsers.CollectionUser

  @doc """
  Returns the list of collection_users.

  ## Examples

      iex> list_collection_users()
      [%CollectionUser{}, ...]

  """
  def list_collection_users do
    Repo.all(CollectionUser)
  end

  @doc """
  Gets a single collection_user.

  Raises `Ecto.NoResultsError` if the User collection does not exist.

  ## Examples

      iex> get_collection_user!(123)
      %CollectionUser{}

      iex> get_collection_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_collection_user!(id), do: Repo.get!(CollectionUser, id)

  @doc """
  Creates a collection_user.

  ## Examples

      iex> create_collection_user(%{field: value})
      {:ok, %CollectionUser{}}

      iex> create_collection_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_collection_user(attrs \\ %{}) do
    %CollectionUser{}
    |> CollectionUser.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a collection_user.

  ## Examples

      iex> update_collection_user(collection_user, %{field: new_value})
      {:ok, %CollectionUser{}}

      iex> update_collection_user(collection_user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_collection_user(%CollectionUser{} = collection_user, attrs) do
    collection_user
    |> CollectionUser.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a collection_user.

  ## Examples

      iex> delete_collection_user(collection_user)
      {:ok, %CollectionUser{}}

      iex> delete_collection_user(collection_user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_collection_user(%CollectionUser{} = collection_user) do
    Repo.delete(collection_user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking collection_user changes.

  ## Examples

      iex> change_collection_user(collection_user)
      %Ecto.Changeset{data: %CollectionUser{}}

  """
  def change_collection_user(%CollectionUser{} = collection_user, attrs \\ %{}) do
    CollectionUser.changeset(collection_user, attrs)
  end
end
