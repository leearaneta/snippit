defmodule Snippit.Repo.Migrations.EnableFuzzyExtensions do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION pg_trgm"
    execute "CREATE EXTENSION fuzzystrmatch"
  end
end
