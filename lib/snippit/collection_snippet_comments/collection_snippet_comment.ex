defmodule Snippit.CollectionSnippetComments.CollectionSnippetComment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "collection_snippet_comments" do
    field :comment, :string
    field :collection_snippet_id, :id
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(collection_snippet_comment, attrs) do
    collection_snippet_comment
    |> cast(attrs, [:comment])
    |> validate_required([:comment])
  end
end
