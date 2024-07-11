defmodule Snippit.InvitedUsers do
  @moduledoc """
  The InvitedUsers context.
  """

  import Ecto.Query, warn: false
  alias Snippit.Repo

  alias Snippit.InvitedUsers.InvitedUser

  @doc """
  Returns the list of invited_users.

  ## Examples

      iex> list_invited_users()
      [%InvitedUser{}, ...]

  """
  def list_invited_users do
    Repo.all(InvitedUser)
  end

  @doc """
  Gets a single invited_user.

  Raises `Ecto.NoResultsError` if the Invited user does not exist.

  ## Examples

      iex> get_invited_user!(123)
      %InvitedUser{}

      iex> get_invited_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_invited_user!(id), do: Repo.get!(InvitedUser, id)

  @doc """
  Creates a invited_user.

  ## Examples

      iex> create_invited_user(%{field: value})
      {:ok, %InvitedUser{}}

      iex> create_invited_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_invited_user(attrs \\ %{}) do
    %InvitedUser{}
    |> InvitedUser.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a invited_user.

  ## Examples

      iex> update_invited_user(invited_user, %{field: new_value})
      {:ok, %InvitedUser{}}

      iex> update_invited_user(invited_user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_invited_user(%InvitedUser{} = invited_user, attrs) do
    invited_user
    |> InvitedUser.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a invited_user.

  ## Examples

      iex> delete_invited_user(invited_user)
      {:ok, %InvitedUser{}}

      iex> delete_invited_user(invited_user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_invited_user(%InvitedUser{} = invited_user) do
    Repo.delete(invited_user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking invited_user changes.

  ## Examples

      iex> change_invited_user(invited_user)
      %Ecto.Changeset{data: %InvitedUser{}}

  """
  def change_invited_user(%InvitedUser{} = invited_user, attrs \\ %{}) do
    InvitedUser.changeset(invited_user, attrs)
  end
end
