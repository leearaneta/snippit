defmodule Snippit.SnippetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Snippit.Snippets` context.
  """

  @doc """
  Generate a snippet.
  """
  def snippet_fixture(attrs \\ %{}) do
    {:ok, snippet} =
      attrs
      |> Enum.into(%{
        description: "some description",
        end: "120.5",
        start: "120.5",
        url: "some url"
      })
      |> Snippit.Snippets.create_snippet()

    snippet
  end
end
