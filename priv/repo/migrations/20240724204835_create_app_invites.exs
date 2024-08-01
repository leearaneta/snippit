defmodule Snippit.Repo.Migrations.CreateAppInvites do
  use Ecto.Migration

  def change do
    create table(:app_invites) do
      add :email, :string, null: false
      add :from_user_id, references(:users, on_delete: :delete_all)
      add :collection_id, references(:collections, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:app_invites, [:email])
    create index(:app_invites, [:from_user_id])
    create index(:app_invites, [:collection_id])
    create index(:app_invites, [:email, :collection_id], unique: true)
  end
end
