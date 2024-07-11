defmodule Snippit.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query, warn: false
  alias Hex.API.User
  alias Snippit.Collections.Collection
  alias Snippit.Repo
  alias Snippit.Users.User


  def get_user_attrs_by_session_token(token) do
    url = "https://api.spotify.com/v1/me"

    headers = ["Authorization": "Bearer #{token}"]
    case HTTPoison.get(url, headers) do
      {:ok, %{body: raw}} ->
        case Poison.decode!(raw) do
          %{"id" => spotify_id, "display_name" => username, "email" => email} ->
            %{spotify_id: spotify_id, username: username, email: email}
          _ -> nil
        end
      _ -> nil
    end
  end

  def get_user_by_session_token(token) do
    attrs = get_user_attrs_by_session_token(token)
    if attrs do
      get_user_by_spotify_id(attrs.spotify_id)
    else
      nil
    end
  end

  def get_user_by_spotify_id(spotify_id) when is_binary(spotify_id) do
    Repo.one(User, spotify_id: spotify_id)
  end

  def get_user!(id), do: Repo.get!(User, id)

  def register_user(attrs) do
    Repo.transaction(fn ->
      {:ok, user} = %User{}
      |> User.registration_changeset(attrs)
      |> Repo.insert()

      %Collection{
        name: "My Snippets",
        description: "baby's first snippets :')",
        is_private: true,
        created_by_id: user.id
      }
      |> Repo.insert()

      user
    end)
  end
end
