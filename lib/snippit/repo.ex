defmodule Snippit.Repo do
  use Ecto.Repo,
    otp_app: :snippit,
    adapter: Ecto.Adapters.Postgres
end
