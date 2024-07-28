defmodule Snippit.CollectionInvites do
  @moduledoc """
  The CollectionInvites context.
  """

  import Ecto.Query, warn: false
  alias Snippit.Repo

  alias Snippit.CollectionInvites.CollectionInvite

  @doc """
  Returns the list of collection_invites.

  ## Examples

      iex> list_collection_invites()
      [%CollectionInvite{}, ...]

  """
  def list_collection_invites do
    Repo.all(CollectionInvite)
  end

  @doc """
  Gets a single collection_invite.

  Raises `Ecto.NoResultsError` if the Collection invite does not exist.

  ## Examples

      iex> get_collection_invite!(123)
      %CollectionInvite{}

      iex> get_collection_invite!(456)
      ** (Ecto.NoResultsError)

  """
  def get_collection_invite!(id), do: Repo.get!(CollectionInvite, id)

  @doc """
  Creates a collection_invite.

  ## Examples

      iex> create_collection_invite(%{field: value})
      {:ok, %CollectionInvite{}}

      iex> create_collection_invite(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_collection_invite(attrs \\ %{}) do
    %CollectionInvite{}
    |> CollectionInvite.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a collection_invite.

  ## Examples

      iex> update_collection_invite(collection_invite, %{field: new_value})
      {:ok, %CollectionInvite{}}

      iex> update_collection_invite(collection_invite, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_collection_invite(%CollectionInvite{} = collection_invite, attrs) do
    collection_invite
    |> CollectionInvite.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a collection_invite.

  ## Examples

      iex> delete_collection_invite(collection_invite)
      {:ok, %CollectionInvite{}}

      iex> delete_collection_invite(collection_invite)
      {:error, %Ecto.Changeset{}}

  """
  def delete_collection_invite(%CollectionInvite{} = collection_invite) do
    Repo.delete(collection_invite)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking collection_invite changes.

  ## Examples

      iex> change_collection_invite(collection_invite)
      %Ecto.Changeset{data: %CollectionInvite{}}

  """
  def change_collection_invite(%CollectionInvite{} = collection_invite, attrs \\ %{}) do
    CollectionInvite.changeset(collection_invite, attrs)
  end
end
