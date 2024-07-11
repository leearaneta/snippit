defmodule Snippit.CollectionSnippetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Snippit.CollectionSnippets` context.
  """

  @doc """
  Generate a collection_snippet.
  """
  def collection_snippet_fixture(attrs \\ %{}) do
    {:ok, collection_snippet} =
      attrs
      |> Enum.into(%{
        index: 42
      })
      |> Snippit.CollectionSnippets.create_collection_snippet()

    collection_snippet
  end
end
