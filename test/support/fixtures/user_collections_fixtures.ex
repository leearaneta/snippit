defmodule Snippit.CollectionUsersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Snippit.CollectionUsers` context.
  """

  @doc """
  Generate a collection_user.
  """
  def collection_user_fixture(attrs \\ %{}) do
    {:ok, collection_user} =
      attrs
      |> Enum.into(%{
        is_editor: true,
      })
      |> Snippit.CollectionUsers.create_collection_user()

    collection_user
  end
end
