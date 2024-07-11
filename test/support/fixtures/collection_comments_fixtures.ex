defmodule Snippit.CollectionCommentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Snippit.CollectionComments` context.
  """

  @doc """
  Generate a collection_comment.
  """
  def collection_comment_fixture(attrs \\ %{}) do
    {:ok, collection_comment} =
      attrs
      |> Enum.into(%{
        comment: "some comment"
      })
      |> Snippit.CollectionComments.create_collection_comment()

    collection_comment
  end
end
