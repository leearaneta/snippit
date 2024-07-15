defmodule SnippitWeb.AuthController do
  use SnippitWeb, :controller

  def get_authorize_url() do
    client_id = Application.fetch_env!(:snippit, :spotify_auth)[:client_id]
    client_secret = Application.fetch_env!(:snippit, :spotify_auth)[:client_secret]

    response_type = "code"
    scope = "streaming user-read-email user-read-private user-modify-playback-state"
    base_url = SnippitWeb.Endpoint.url()
    callback_url = URI.merge(base_url, "/auth/callback")
    state = for _ <- 1..16, into: "", do: <<Enum.random(~c'0123456789abcdef')>>
    query = %{
      response_type: response_type,
      client_id: client_id,
      scope: scope,
      redirect_uri: callback_url,
      state: state
    } |> URI.encode_query()

    "https://accounts.spotify.com/authorize/?" <> query
  end

  def login(conn, _) do
    Phoenix.Controller.redirect(conn, external: get_authorize_url())
  end

  def callback(conn, params) do
    client_id = Application.fetch_env!(:snippit, :spotify_auth)[:client_id]
    client_secret = Application.fetch_env!(:snippit, :spotify_auth)[:client_secret]

    url = "https://accounts.spotify.com/api/token"
    code = params["code"]
    base_url = SnippitWeb.Endpoint.url()
    # this should just be in config
    callback_url = URI.merge(base_url, "/auth/callback")

    body = %{
      code: code,
      redirect_uri: callback_url,
      grant_type: "authorization_code"
    } |> URI.encode_query()
    headers = [
      "Authorization": "Basic " <> Base.encode64("#{client_id}:#{client_secret}"),
      "Content-Type": "application/x-www-form-urlencoded"
    ]
    {:ok, response} = HTTPoison.post(url, body, headers)
    %{
      "access_token" => access_token,
      "refresh_token" => refresh_token,
    } = Poison.decode!(response.body)

    user = Snippit.Users.get_user_attrs_by_session_token(access_token)
    db_user = Snippit.Users.get_user_by_spotify_id(user.spotify_id)
    if is_nil(db_user) do
      Snippit.Users.register_user(user)
    end

    conn = SnippitWeb.UserAuth.log_in_user(conn, access_token, refresh_token)
    Phoenix.Controller.redirect(conn, to: ~p"/")
  end

  def logout(conn, _params) do
    IO.inspect(conn)
    SnippitWeb.UserAuth.log_out_user(conn)
  end

end
