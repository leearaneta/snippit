defmodule Snippit.InvitedUsersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Snippit.InvitedUsers` context.
  """

  @doc """
  Generate a invited_user.
  """
  def invited_user_fixture(attrs \\ %{}) do
    {:ok, invited_user} =
      attrs
      |> Enum.into(%{
        email: "some email"
      })
      |> Snippit.InvitedUsers.create_invited_user()

    invited_user
  end
end
