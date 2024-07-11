defmodule Snippit.CollectionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Snippit.Collections` context.
  """

  @doc """
  Generate a collection.
  """
  def collection_fixture(attrs \\ %{}) do
    {:ok, collection} =
      attrs
      |> Enum.into(%{
        description: "some description",
        is_private: true,
        name: "some name"
      })
      |> Snippit.Collections.create_collection()

    collection
  end
end
