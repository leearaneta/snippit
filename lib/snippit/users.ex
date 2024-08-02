defmodule Snippit.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query, warn: false
  alias Snippit.CollectionInvites
  alias Snippit.AppInvites.AppInvite
  alias Hex.API.User
  alias Snippit.Collections.Collection
  alias Snippit.Repo
  alias Snippit.Users.User

  def get_user_attrs_by_session_token(token) do
    url = "https://api.spotify.com/v1/me"

    headers = ["Authorization": "Bearer #{token}"]
    case HTTPoison.get(url, headers) do
      {:ok, %{body: raw}} ->
        IO.inspect(raw)
        IO.inspect(headers)
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

  def search_users_by_username(search, ids_to_omit \\ []) do
    start_character = String.slice(search, 0..1)

    from(
      u in User,
      where: ilike(u.username, ^"#{start_character}%"),
      where: u.id not in ^ids_to_omit,
      where: fragment("SIMILARITY(?, ?) > 0",  u.username, ^search),
      order_by: fragment("LEVENSHTEIN(?, ?)", u.username, ^search)
    )
    |> Repo.all()
  end

  def get_user_by_spotify_id(spotify_id) when is_binary(spotify_id) do
    query = from u in User,
      select: u,
      where: u.spotify_id == ^spotify_id
    Repo.one(query)
  end

  def get_user_by_email(email) when is_binary(email) do
    query = from u in User,
      select: u,
      where: u.email == ^email
    Repo.one(query)
  end

  def get_user!(id), do: Repo.get!(User, id)

  defp create_collection_invites_from_app_invites(%User{} = user) do
    Repo.transaction(fn ->
      query = from invite in AppInvite,
      select: invite,
      where: invite.email == ^user.email

      collection_invite_tasks = query
      |> Repo.all()
      |> Enum.map(&Map.from_struct/1)
      |> Enum.map(fn attrs -> Map.delete(attrs, :email) end)
      |> Enum.map(fn attrs -> Map.put(attrs, :user_id, user.id) end)
      |> Enum.map(fn attrs ->
        Task.async(fn ->
          CollectionInvites.create_collection_invite(attrs)
        end)
      end)
      Task.await_many(collection_invite_tasks) |> IO.inspect()
      Repo.delete_all(from(invite in AppInvite, where: invite.email == ^user.email))
    end)
  end

  def register_user(attrs) do
    {:ok, user} = Repo.transaction(fn ->
      with  {:ok, user} <- %User{}
              |> User.registration_changeset(attrs)
              |> Repo.insert(),
            {:ok, _} <- %Collection{
              name: "My Snippets",
              description: "#{user.username}'s first collection!",
              is_private: true,
              created_by_id: user.id
            } |> Repo.insert()
      do user
      else err -> err
      end
    end)
    {:ok, _} = create_collection_invites_from_app_invites(user)
    {:ok, user}
  end
end
