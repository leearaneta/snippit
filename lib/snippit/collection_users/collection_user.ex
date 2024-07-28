defmodule Snippit.CollectionUsers.CollectionUser do
  alias Snippit.Users.User

  use Ecto.Schema
  import Ecto.Changeset

  schema "collection_users" do
    field :is_editor, :boolean, default: false
    field :collection_id, :id
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(collection_user, attrs) do
    collection_user
    |> cast(attrs, [:is_editor, :collection_id, :user_id])
    |> validate_required([:is_editor, :collection_id, :user_id])
  end
end
