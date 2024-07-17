defmodule Snippit.Snippets do
  @moduledoc """
  The Snippets context.
  """

  import Ecto.Query, warn: false
  alias Snippit.CollectionSnippets.CollectionSnippet
  alias Snippit.CollectionSnippets
  alias Snippit.Repo
  alias Snippit.Snippets.Snippet

  @doc """
  Returns the list of snippets.

  ## Examples

      iex> list_snippets()
      [%Snippet{}, ...]

  """
  def list_snippets do
    Repo.all(Snippet)
  end

  @doc """
  Gets a single snippet.

  Raises `Ecto.NoResultsError` if the Snippet does not exist.

  ## Examples

      iex> get_snippet!(123)
      %Snippet{}

      iex> get_snippet!(456)
      ** (Ecto.NoResultsError)

  """
  def get_snippet!(id), do: Repo.get!(Snippet, id)

  @doc """
  Creates a snippet.

  ## Examples

      iex> create_snippet(%{field: value})
      {:ok, %Snippet{}}

      iex> create_snippet(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  defp create_snippet_standalone(attrs) do
    %Snippet{}
    |> Snippet.changeset(attrs)
    |> Repo.insert()
  end

  def create_snippet(attrs \\ %{}) do
    Repo.transaction(fn ->
      with  {:ok, %Snippet{id: snippet_id, created_by_id: added_by_id}} <- create_snippet_standalone(attrs),
            {:ok, collection_snippet} <- attrs
              |> Map.put(:snippet_id, snippet_id)
              |> Map.put(:added_by_id, added_by_id)
              |> CollectionSnippets.create_collection_snippet()
      do    collection_snippet
      else  error -> IO.inspect(error)
      end
    end)
  end

  @doc """
  Updates a snippet.

  ## Examples

      iex> update_snippet(snippet, %{field: new_value})
      {:ok, %Snippet{}}

      iex> update_snippet(snippet, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_snippet(%Snippet{} = snippet, attrs) do
    snippet
    |> Snippet.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a snippet.

  ## Examples

      iex> delete_snippet(snippet)
      {:ok, %Snippet{}}

      iex> delete_snippet(snippet)
      {:error, %Ecto.Changeset{}}

  """
  def delete_snippet(%Snippet{} = snippet) do
    Repo.delete(snippet)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking snippet changes.

  ## Examples

      iex> change_snippet(snippet)
      %Ecto.Changeset{data: %Snippet{}}

  """
  def change_snippet(%Snippet{} = snippet, attrs \\ %{}) do
    Snippet.changeset(snippet, attrs)
  end
end
