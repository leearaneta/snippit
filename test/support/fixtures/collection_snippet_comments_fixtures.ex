defmodule Snippit.CollectionSnippetCommentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Snippit.CollectionSnippetComments` context.
  """

  @doc """
  Generate a collection_snippet_comment.
  """
  def collection_snippet_comment_fixture(attrs \\ %{}) do
    {:ok, collection_snippet_comment} =
      attrs
      |> Enum.into(%{
        comment: "some comment"
      })
      |> Snippit.CollectionSnippetComments.create_collection_snippet_comment()

    collection_snippet_comment
  end
end
