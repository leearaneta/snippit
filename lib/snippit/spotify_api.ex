defmodule Snippit.SpotifyApi do

  # use Agent

  # @client_id Application.compile_env(:snippit, :spotify_auth)[:client_id]
  # @client_secret Application.compile_env(:snippit, :spotify_auth)[:client_secret]

  # defp fetch_tokens() do
  #   url = "https://accounts.spotify.com/api/token"

  #   body = %{ grant_type: "client_credentials" } |> URI.encode_query()

  #   headers = [
  #     "Authorization": "Basic " <> Base.encode64("#{@client_id}:#{@client_secret}"),
  #     "Content-Type": "application/x-www-form-urlencoded"
  #   ]
  #   {:ok, response} = HTTPoison.post(url, body, headers)
  #   %{
  #     "access_token" => access_token,
  #     "refresh_token" => refresh_token,
  #   } = Poison.decode!(response.body)

  #   %{access_token: access_token, refresh_token: refresh_token}
  # end

  # def start_link(_initial_value) do
  #   Agent.start_link(&fetch_tokens/0, name: __MODULE__)
  # end

  defp get(token, url, params) do
    headers = ["Authorization": "Bearer #{token}"]

    case HTTPoison.get(url <> "?" <> URI.encode_query(params), headers) do
      {:ok, response} -> Poison.decode!(response.body)
      error -> IO.inspect(error)
    end
  end

  defp put(token, url, body, params \\ %{}) do
    headers = [
      "Authorization": "Bearer #{token}",
      "Content-Type": "application/json"
    ]

    case HTTPoison.put(url <> "?" <> URI.encode_query(params), Poison.encode!(body), headers) do
      {:ok, response} -> {:ok, response}
      other -> IO.inspect(other)
    end
  end

  defp get_relevant_attrs_for_track(track) do
    %{
      album: track["album"]["name"],
      thumbnail_url: List.last(track["album"]["images"])["url"],
      image_url: List.first(track["album"]["images"])["url"],
      spotify_url: track["uri"],
      artist: track["artists"]
        |> Enum.map(fn artist -> artist["name"] end)
        |> Enum.join(" "),
      track: track["name"],
      duration_ms: track["duration_ms"]
    }
  end

  def search_tracks(token, search_params) do
    keys = ["track", "album", "artist"]
    search_query = search_params
      |> Map.take(keys)
      |> Enum.filter(fn {_, v} -> v != "" end)
      |> Enum.map(fn {k, v} -> k <> ":" <> v end)
      |> Enum.join(" ")

    if search_query == "" do
      []
    else
      params = %{q: search_query, type: "track"}
      response = get(token, "https://api.spotify.com/v1/search", params)
      response["tracks"]["items"] |> Enum.map(&get_relevant_attrs_for_track/1)
    end
  end

  def play_track_from_ms(token, device_id, track_id, from_ms) do
    body = %{uris: [track_id], position_ms: from_ms}
    params = %{device_id: device_id}
    put(token, "https://api.spotify.com/v1/me/player/play", body, params)
  end

  def pause(token, device_id) do
    params = %{device_id: device_id}
    put(token, "https://api.spotify.com/v1/me/player/play", %{}, params)
  end

  def set_device_id(token, device_id) do
    body = %{device_ids: [device_id]}
    put(token, "https://api.spotify.com/v1/me/player", body)
  end
end
