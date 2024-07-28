defmodule Snippit.Collections.Collection do
  alias Snippit.Users.User
  alias Snippit.CollectionInvites.CollectionInvite
  alias Snippit.CollectionUsers.CollectionUser
  alias Snippit.CollectionSnippets.CollectionSnippet

  use Ecto.Schema
  import Ecto.Changeset

  schema "collections" do
    field :name, :string
    field :description, :string
    field :is_private, :boolean, default: false
    field :is_editor, :boolean, virtual: true
    field :is_invite, :boolean, virtual: true

    belongs_to :created_by, User, foreign_key: :created_by_id
    has_many :collection_snippets, CollectionSnippet, foreign_key: :collection_id
    has_many :collection_users, CollectionUser
    has_many :collection_invites, CollectionInvite

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
