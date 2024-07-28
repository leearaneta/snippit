defmodule Snippit.InvitesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Snippit.Invites` context.
  """

  @doc """
  Generate a invite.
  """
  def invite_fixture(attrs \\ %{}) do
    {:ok, invite} =
      attrs
      |> Enum.into(%{

      })
      |> Snippit.Invites.create_invite()

    invite
  end
end
