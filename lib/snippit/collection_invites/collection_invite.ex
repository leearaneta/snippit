defmodule Snippit.CollectionInvites.CollectionInvite do
  use Ecto.Schema
  import Ecto.Changeset

  alias Snippit.Users.User

  schema "collection_invites" do

    field :user_id, :id
    field :collection_id, :id

    belongs_to :from_user, User, foreign_key: :from_user_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(collection_invite, attrs) do
    collection_invite
    |> cast(attrs, [:user_id, :from_user_id, :collection_id])
    |> validate_required([:user_id, :from_user_id, :collection_id])
  end
end
