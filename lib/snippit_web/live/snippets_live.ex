defmodule SnippitWeb.SnippetsLive do
  use SnippitWeb, :live_component
  import SnippitWeb.CustomComponents, warn: false

  alias SnippitWeb.AddSnippet
  alias SnippitWeb.RepostSnippet

  alias Snippit.CollectionSnippets

  alias Snippit.SpotifyApi

  def mount(socket) do
    socket = socket
    |> assign(:now_playing_snippet, nil)
    |> assign(:snippet_to_delete, nil)
    |> assign(:snippet_to_repost, nil)
    |> assign(:show_snippet_info?, false)
    {:ok, socket}
  end

  def play_snippet(socket, snippet) do
    %{
      player_url: player_url,
      user_token: user_token,
      now_playing_snippet: now_playing_snippet,
      show_snippet_info?: show_snippet_info?,
      device_id: device_id,
      device_connected?: device_connected?,
      playing?: playing?
    } = socket.assigns

    socket = if player_url == snippet.snippet.spotify_url && device_connected? do
      if playing? do
        push_event(socket, "pause", %{})
      else
        push_event(socket, "restart", %{})
      end
    else
      Task.start(fn ->
        SpotifyApi.play_track_from_ms(
          user_token,
          device_id,
          snippet.snippet.spotify_url,
          snippet.snippet.start_ms
        )
      end)
      socket
    end

    initialize_audio_payload = snippet.snippet
    |> Map.take([:spotify_url, :start_ms, :end_ms])

    show_snippet_info? = !(now_playing_snippet.id == snippet.id && playing? && !show_snippet_info?)

    socket
    |> assign(:now_playing_snippet, snippet)
    |> assign(:show_snippet_info?, show_snippet_info?)
    |> push_event("initialize_audio", initialize_audio_payload)
  end

  def handle_event("snippet_clicked", %{"id" => id}, socket) do
    if socket.assigns.device_id do
      snippet = socket.assigns.collection_snippets
        |> Enum.find(fn cs -> cs.id == String.to_integer(id) end)
      socket = socket
        |> assign(:now_playing_snippet, snippet)
        |> play_snippet(snippet)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("delete_snippet_clicked", %{"idx" => idx}, socket) do
    snippet = socket.assigns.collection_snippets
      |> Enum.at(String.to_integer(idx))

    socket = socket
      |> assign(:snippet_to_delete, snippet)
      |> push_event("show_modal", %{"id" => "delete_snippet"})

    {:noreply, socket}
  end

  def handle_event("snippet_deleted", _, socket) do
    collection_snippet = socket.assigns.snippet_to_delete
    socket = start_async(socket, :snippet_deleted, fn ->
      case CollectionSnippets.delete_collection_snippet(collection_snippet) do
        {:ok, _} -> collection_snippet
        other -> IO.inspect(other)
      end
    end)
    {:noreply, socket}
  end

  def handle_async(:snippet_deleted, {:ok, _}, socket) do
    socket = socket
      |>  assign(:snippet_to_delete, nil)
      |>  push_event("hide_modal", %{"id" => "delete_snippet"})

    {:noreply, socket}
  end

  def handle_event("repost_snippet_clicked", %{"idx" => idx}, socket) do
    snippet = socket.assigns.collection_snippets
      |> Enum.at(String.to_integer(idx))

    socket = socket
      |> assign(:snippet_to_repost, snippet)
      |> push_event("show_modal", %{"id" => "repost_snippet"})

    {:noreply, socket}
  end

  def handle_event("track_clicked", %{"url" => url}, socket) do
    socket = socket
    |> assign(:now_playing_snippet, nil)
    |> push_event("track_clicked", %{"url" => url})
    {:noreply, socket}
  end

  def handle_event("close_snippet_info_clicked", _, socket) do
    {:noreply, assign(socket, :show_snippet_info?, false)}
  end

  defp get_human_readable_time(ms) do
    secs = trunc(ms / 1000)
    remainder = rem(secs, 60)
    minutes = trunc((secs - remainder) / 60)
    "#{minutes}:#{remainder |> Integer.to_string() |> String.pad_leading(2, "0")}"
  end

  def render(assigns) do
    ~H"""
    <div id="snippets_root">
      <.live_component
        module={RepostSnippet}
        id={:repost}
        user_id={@current_user.id}
        collections={@collections}
        selected_collection={@selected_collection}
        snippet={@snippet_to_repost}
        now_playing_snippet={@now_playing_snippet}
        playing?={@playing?}
        loading?={@loading?}
      />

      <.live_component
        module={AddSnippet}
        id={:create}
        user_token={@user_token}
        user_id={@current_user.id}
        collections={@collections}
        selected_collection={@selected_collection}
        device_id={@device_id}
        device_connected?={@device_connected?}
        playing?={@playing?}
        player_url={@player_url}
        track_ms={@audio_ms}
      />
      <.modal id="delete_snippet">
        <div
          :if={@snippet_to_delete}
          class="h-[36vh] flex flex-col gap-8"
        >
          <div class="text-2xl font-bold"> Delete Snippet </div>
          <div class="flex justify-between">
            <div class="flex-1 flex flex-col gap-8">
              <div class="flex flex-col gap-1">
                <span> Delete snippet? </span>
                <span> This cannot be undone. </span>
              </div>
              <div class="flex gap-8">
                <.button
                  class="w-24"
                  kind="warning"
                  phx-click="snippet_deleted"
                  phx-target={@myself}
                >
                  Delete
                </.button>
                <.button
                  class="w-24"
                  kind="secondary"
                  phx-click={hide_modal("delete_snippet")}
                >
                  Cancel
                </.button>
              </div>
            </div>
            <div
              phx-click="snippet_clicked"
              phx-target={@myself}
              phx-value-id={@snippet_to_delete.id}
            >
              <.snippet_display
                snippet={@snippet_to_delete}
                device_id={@device_id}
                playing?={@now_playing_snippet
                  && @playing?
                  && @snippet_to_delete.id == @now_playing_snippet.id
                }
                loading?={@now_playing_snippet
                  && @loading?
                  && @snippet_to_delete.id == @now_playing_snippet.id
                }
              />
            </div>
          </div>
        </div>
      </.modal>
      <ul
        id="snippets"
        class="flex flex-wrap gap-4"
        phx-hook="snippets"
      >
        <li
          :for={{collection_snippet, i} <- Enum.with_index(@collection_snippets)}
          phx-value-id={collection_snippet.id}
          phx-click="snippet_clicked"
          phx-target={@myself}
          id={"#{collection_snippet.id}"}
          phx-mounted={JS.transition({"duration-200", "opacity-0", "opacity-100"})}
        >
          <.snippet_display
            snippet={collection_snippet}
            playing?={@now_playing_snippet
              && @playing?
              && collection_snippet.id == @now_playing_snippet.id
            }
            loading?={@now_playing_snippet
              && @loading?
              && collection_snippet.id == @now_playing_snippet.id
            }
            device_id={@device_id}
          >
            <div>
              <button
                phx-click="repost_snippet_clicked"
                phx-target={@myself}
                phx-value-idx={i}
                class="opacity-50 transition-opacity hover:opacity-100 pb-1"
              >
                <.icon name="hero-plus" class="w-4 h-4" />
              </button>
              <button
                phx-click="delete_snippet_clicked"
                phx-target={@myself}
                phx-value-idx={i}
                class="opacity-50 transition-opacity hover:opacity-100 pb-1"
              >
                <.icon name="hero-trash" class="w-4 h-4" />
              </button>
            </div>
          </.snippet_display>
        </li>
      </ul>
      <div
        id={"snippet-info-#{@now_playing_snippet.id}"}
        :if={@show_snippet_info? && @now_playing_snippet && @now_playing_snippet.collection_id == @selected_collection.id}
        phx-mounted={JS.show(transition: {"duration-200", "translate-y-16 opacity-0", "translate-y-0 opacity-100"})}
        class="hidden fixed bottom-12 right-12 transition-transform transition-opacity"
      >
        <div class="flex w-[32rem] flex-col gap-4 shadow-2xl rounded-2xl px-8 pb-8 pt-10 bg-white relative">
          <div
            class="absolute right-[15px] top-[15px] cursor-pointer"
            phx-click={"close_snippet_info_clicked"}
            phx-target={@myself}
          >
            <.icon name="hero-x-mark-solid" class="w-4" />
          </div>
          <div class="flex gap-8 justify-between">
            <div class="flex-1">
              <.track_display
                track={@now_playing_snippet.snippet.track}
                artist={@now_playing_snippet.snippet.artist}
                album={@now_playing_snippet.snippet.album}
                thumbnail_url={@now_playing_snippet.snippet.thumbnail_url}
                spotify_url={@now_playing_snippet.snippet.spotify_url}
              />
            </div>
            <div class="flex flex-col items-end overflow-hidden">
              <div>
                <%= get_human_readable_time(@now_playing_snippet.snippet.start_ms) %>
                -
                <%= get_human_readable_time(@now_playing_snippet.snippet.end_ms) %>
              </div>
              <div class="italic text-zinc-600 text-sm overflow-hidden whitespace-nowrap text-ellipsis self-start w-full">
                added by
                <%= @now_playing_snippet.added_by.username %>
              </div>
            </div>
          </div>
          <div :if={@now_playing_snippet.description} class="flex-1">
            <%= @now_playing_snippet.description %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
