defmodule Snippit.AppInvitesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Snippit.AppInvites` context.
  """

  @doc """
  Generate a app_invite.
  """
  def app_invite_fixture(attrs \\ %{}) do
    {:ok, app_invite} =
      attrs
      |> Enum.into(%{

      })
      |> Snippit.AppInvites.create_app_invite()

    app_invite
  end
end
