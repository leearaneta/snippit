defmodule Snippit.AppInvites.AppInvite do
  use Ecto.Schema
  import Ecto.Changeset

  schema "app_invites" do

    field :email, :string
    field :from_user_id, :id
    field :collection_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(app_invite, attrs) do
    app_invite
    |> cast(attrs, [:email, :from_user_id, :collection_id])
    |> validate_required([:email, :from_user_id, :collection_id])
  end

  def form_changeset(app_invite, attrs) do
    email_regex = ~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*$/i
    app_invite
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> validate_format(:email, email_regex)
  end
end
