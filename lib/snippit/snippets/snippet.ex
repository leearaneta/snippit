defmodule Snippit.Snippets.Snippet do
  alias Snippit.CollectionSnippets.CollectionSnippet
  alias Snippit.Collections.Collection
  use Ecto.Schema
  import Ecto.Changeset

  schema "snippets" do
    field :start_ms, :integer
    field :end_ms, :integer
    field :duration_ms, :integer
    field :track, :string
    field :artist, :string
    field :album, :string
    field :thumbnail_url, :string
    field :image_url, :string
    field :spotify_url, :string
    field :created_by_id, :id

    many_to_many :collections, Collection, join_through: CollectionSnippet

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(snippet, attrs) do
    snippet
    |> cast(attrs, [:created_by_id, :spotify_url, :start_ms, :end_ms, :duration_ms, :track, :artist, :album, :thumbnail_url, :image_url])
    |> validate_required([:created_by_id, :spotify_url, :start_ms, :end_ms, :duration_ms, :track, :artist, :album, :thumbnail_url, :image_url])
  end
end
