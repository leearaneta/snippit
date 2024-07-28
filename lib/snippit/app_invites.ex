defmodule Snippit.AppInvites do
  @moduledoc """
  The AppInvites context.
  """

  import Ecto.Query, warn: false
  alias Snippit.Repo

  alias Snippit.AppInvites.AppInvite

  @doc """
  Returns the list of app_invites.

  ## Examples

      iex> list_app_invites()
      [%AppInvite{}, ...]

  """
  def list_app_invites do
    Repo.all(AppInvite)
  end

  @doc """
  Gets a single app_invite.

  Raises `Ecto.NoResultsError` if the App invite does not exist.

  ## Examples

      iex> get_app_invite!(123)
      %AppInvite{}

      iex> get_app_invite!(456)
      ** (Ecto.NoResultsError)

  """
  def get_app_invite!(id), do: Repo.get!(AppInvite, id)

  @doc """
  Creates a app_invite.

  ## Examples

      iex> create_app_invite(%{field: value})
      {:ok, %AppInvite{}}

      iex> create_app_invite(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_app_invite(attrs \\ %{}) do
    %AppInvite{}
    |> AppInvite.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a app_invite.

  ## Examples

      iex> update_app_invite(app_invite, %{field: new_value})
      {:ok, %AppInvite{}}

      iex> update_app_invite(app_invite, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_app_invite(%AppInvite{} = app_invite, attrs) do
    app_invite
    |> AppInvite.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a app_invite.

  ## Examples

      iex> delete_app_invite(app_invite)
      {:ok, %AppInvite{}}

      iex> delete_app_invite(app_invite)
      {:error, %Ecto.Changeset{}}

  """
  def delete_app_invite(%AppInvite{} = app_invite) do
    Repo.delete(app_invite)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking app_invite changes.

  ## Examples

      iex> change_app_invite(app_invite)
      %Ecto.Changeset{data: %AppInvite{}}

  """
  def change_app_invite(%AppInvite{} = app_invite, attrs \\ %{}) do
    AppInvite.changeset(app_invite, attrs)
  end

  def change_app_invite_form(%AppInvite{} = app_invite, attrs \\ %{}) do
    AppInvite.form_changeset(app_invite, attrs)
  end
end
