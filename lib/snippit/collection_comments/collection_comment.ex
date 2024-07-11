defmodule Snippit.CollectionComments.CollectionComment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "collection_comments" do
    field :comment, :string
    field :collection_id, :id
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(collection_comment, attrs) do
    collection_comment
    |> cast(attrs, [:comment])
    |> validate_required([:comment])
  end
end
