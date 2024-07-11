defmodule Snippit.CollectionUsers.CollectionUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "collection_users" do
    field :is_pending, :boolean, default: false
    field :is_editor, :boolean, default: false
    field :collection_id, :id
    field :user_id, :id
    field :invited_user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(collection_user, attrs) do
    collection_user
    |> cast(attrs, [:is_pending, :is_editor])
    |> validate_required([:is_pending, :is_editor, :collection_id])
  end
end
