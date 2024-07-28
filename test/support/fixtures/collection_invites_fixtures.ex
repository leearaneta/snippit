defmodule Snippit.CollectionInvitesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Snippit.CollectionInvites` context.
  """

  @doc """
  Generate a collection_invite.
  """
  def collection_invite_fixture(attrs \\ %{}) do
    {:ok, collection_invite} =
      attrs
      |> Enum.into(%{

      })
      |> Snippit.CollectionInvites.create_collection_invite()

    collection_invite
  end
end
