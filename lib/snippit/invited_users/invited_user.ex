defmodule Snippit.InvitedUsers.InvitedUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "invited_users" do
    field :email, :string
    field :invited_by_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(invited_user, attrs) do
    invited_user
    |> cast(attrs, [:email])
    |> validate_required([:email])
  end
end
