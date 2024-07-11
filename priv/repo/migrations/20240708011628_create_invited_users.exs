defmodule Snippit.Repo.Migrations.CreateInvitedUsers do
  use Ecto.Migration

  def change do
    create table(:invited_users) do
      add :email, :string, null: false
      add :invited_by_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:invited_users, [:invited_by_id])
  end
end
