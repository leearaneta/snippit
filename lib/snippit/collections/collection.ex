defmodule Snippit.Collections.Collection do
  alias Snippit.CollectionSnippets.CollectionSnippet
  use Ecto.Schema
  import Ecto.Changeset

  schema "collections" do
    field :name, :string
    field :description, :string
    field :is_private, :boolean, default: false
    field :created_by_id, :id

    has_many :collection_snippets, CollectionSnippet, foreign_key: :collection_id
    timestamps(type: :utc_datetime)
  end

  @doc false
  def form_changeset(collection, attrs) do
    collection
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  def changeset(collection, attrs) do
    collection
    |> cast(attrs, [:name, :description, :is_private, :created_by_id])
    |> validate_required([:name, :created_by_id])
  end
end
