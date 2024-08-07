defmodule Snippit.CollectionSnippets.CollectionSnippet do
  alias Snippit.Users.User
  alias Snippit.Snippets.Snippet
  use Ecto.Schema
  import Ecto.Changeset

  schema "collection_snippets" do
    field :index, :integer
    field :collection_id, :id
    field :from_collection_id, :id
    field :description, :string

    belongs_to :snippet, Snippet
    belongs_to :added_by, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(collection_snippet, attrs) do
    collection_snippet
    |> cast(attrs, [:index, :collection_id, :from_collection_id, :snippet_id, :added_by_id, :description])
    |> validate_required([:collection_id, :snippet_id, :added_by_id])
    |> unique_constraint([:collection_id, :snippet_id],
      name: :collection_snippets_collection_id_snippet_id_index,
      message: "Snippet already belongs to that collection!"
    )
  end
end
