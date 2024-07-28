defmodule SnippitWeb.HomeLive do
  alias Snippit.Collections
  alias Snippit.CollectionSnippets
  alias SnippitWeb.CustomComponents
  alias SnippitWeb.CollectionsIndex

  alias SnippitWeb.AddSnippet
  alias SnippitWeb.RepostSnippet
  alias Snippit.CollectionSnippets.CollectionSnippet
  alias Snippit.Repo

  alias Snippit.SpotifyApi

  import CustomComponents, warn: false
  import Ecto.Query, warn: false

  use SnippitWeb, :live_view
  on_mount {SnippitWeb.UserAuth, :ensure_authenticated}

  def mount(params, session, socket) do
    current_user = socket.assigns.current_user
    collections = Collections.get_collections_query(current_user)
    |> Repo.all()

    collection_invites = Collections.get_collection_invites_query(current_user) |> Repo.all()
    collections_by_id = collections ++ collection_invites
    |> Enum.group_by(fn collection -> collection.id end)
    |> Map.new(fn {k, v} -> {k, hd(v)} end)

    socket = socket
    |> assign(:collections_by_id, collections_by_id)
    |> load_selected_collection(params, collections_by_id)
    |> assign(:collection_snippets, [])
    |> assign(:user_token, session["user_token"])
    |> assign(:device_id, nil)
    |> assign(:playing?, false)
    |> assign(:loading?, false)
    |> assign(:player_url, nil)
    |> assign(:audio_ms, 0)
    |> assign(:now_playing_snippet, nil)
    |> assign(:snippet_to_delete, nil)
    |> assign(:snippet_to_repost, nil)

    {:ok, socket}
  end

  defp load_selected_collection(socket, params, collections_by_id) do
    if Map.get(socket.assigns, :selected_collection) do
      CollectionSnippets.unsubscribe(socket.assigns.selected_collection.id)
    end

    collection_id = params["collection"] && String.to_integer(params["collection"]) || nil
    selected_collection = Map.get(collections_by_id, collection_id)
    socket = socket
    |> assign(:selected_collection, selected_collection)
    |> assign(:collection_snippets, [])

    if selected_collection do
      CollectionSnippets.subscribe(selected_collection.id)
      socket
        |> start_async(:load_collection_snippets, fn ->
          from(cs in CollectionSnippet,
            where: cs.collection_id == ^selected_collection.id,
            preload: [:snippet, :added_by]
          )
          |> Repo.all()
        end)
    else
      if collection_id do
        put_flash(socket, :error, "sorry, we can't find that collection.")
      else
        socket
      end
    end
  end

  def handle_async(:load_collection_snippets, {:ok, collection_snippets}, socket) do
    {:noreply, assign(socket, :collection_snippets, collection_snippets)}
  end

  def handle_params(params, _, socket) do
    {:noreply, load_selected_collection(socket, params, socket.assigns.collections_by_id) }
  end

  def handle_event("player_ready", device_id, socket) do
    # SpotifyApi.set_device_id(socket.assigns.user_token, device_id)
    {:noreply, assign(socket, :device_id, device_id)}
  end


  def handle_event("device_not_connected", _, socket) do
    {:noreply, reset_audio_state(socket)}
  end

  def handle_event("player_state_changed", state, socket) do
    socket = socket
      |> assign(:playing?, !state["paused"])
      |> assign(:player_url, state["player_url"])
      |> assign(:loading?, state["loading"])
      |> assign(:audio_ms, state["position"])
      |> push_event("player_state_changed", %{"playing" => !state["paused"], "position" => state["position"]})
    {:noreply, socket}
  end

  def play_snippet(socket, snippet) do
    socket = if socket.assigns.player_url == snippet.snippet.spotify_url do
      if socket.assigns.playing? do
        push_event(socket, "pause", %{})
      else
        push_event(socket, "restart", %{})
      end
    else
      Task.start(fn ->
        SpotifyApi.play_track_from_ms(
          socket.assigns.user_token,
          socket.assigns.device_id,
          snippet.snippet.spotify_url,
          snippet.snippet.start_ms
        )
      end)
      socket
    end

    initialize_audio_payload = snippet.snippet
      |> Map.take([:spotify_url, :start_ms, :end_ms])

    socket
      |> assign(:now_playing_snippet, snippet)
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

  defp reset_audio_state(socket) do
    socket
    |> assign(:player_url, nil)
    |> assign(:now_playing_snippet, nil)
    |> assign(:playing?, false)
  end

  def handle_event("track_clicked", _, socket) do
    url = socket.assigns.now_playing_snippet.snippet.spotify_url
    socket = socket
    |> reset_audio_state()
    |> push_event("track_clicked", %{"url" => url})
    {:noreply, socket}
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

  def handle_info({:snippet_deleted, %CollectionSnippet{id: id}}, socket) do
    socket = Phoenix.Component.update(socket, :collection_snippets, fn collection_snippets ->
      Enum.filter(collection_snippets, fn collection_snippet ->
        id != collection_snippet.id
      end)
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

  def handle_info({:snippet_created, collection_snippet}, socket) do
    socket = Phoenix.Component.update(socket, :collection_snippets, fn collection_snippets ->
      [Repo.preload(collection_snippet, :added_by) | collection_snippets]
    end)

    {:noreply, socket}
  end

  def handle_info({:collection_created, collection}, socket) do
    socket = socket
      |>  Phoenix.Component.update(:collections_by_id, fn collections_by_id ->
          Map.put(collections_by_id, collection.id, collection)
        end)
      |>  push_patch(to: ~p"/?collection=#{collection.id}")

    {:noreply, socket}
  end

  def handle_info({:collection_edited, edited_collection}, socket) do
    socket = socket
    |>  Phoenix.Component.update(:collections_by_id, fn collections_by_id ->
          Map.put(collections_by_id, edited_collection.id, edited_collection)
        end)
    {:noreply, socket}
  end

  def handle_info({:collection_deleted, collection_id}, socket) do
    socket = Phoenix.Component.update(socket, :collections_by_id, fn collections_by_id ->
      Map.delete(collections_by_id, collection_id)
    end)
    if socket.assigns.selected_collection.id == collection_id do
      {:noreply, assign(socket, :selected_collection, nil)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("accept_invite_clicked", _, socket) do
    collection = socket.assigns.selected_collection
    socket = start_async(socket, :accept_invite, fn ->
      case Collections.accept_invite(collection) do
        {:ok, _} -> collection
        {:error, error} -> IO.inspect(error)
      end
    end)
    {:noreply, socket}
  end

  def handle_async(:accept_invite, {:ok, collection}, socket) do
    collection = Collections.get_collections_query(socket.assigns.current_user)
      |> where([c], c.id == ^collection.id)
      |> Repo.one()

    socket = socket
    |>  Phoenix.Component.update(:collections_by_id, fn collections_by_id ->
          Map.put(collections_by_id, collection.id, collection)
        end)
    |>  assign(:selected_collection, collection)
    {:noreply, socket}
  end

  def handle_event("reject_invite_clicked", _, socket) do
    collection = socket.assigns.selected_collection
    socket = start_async(socket, :reject_invite, fn ->
      case Collections.reject_invite(collection) do
        {:ok, _} -> collection
        {:error, error} -> IO.inspect(error)
      end
    end)
    {:noreply, socket}
  end

  def handle_async(:reject_invite, {:ok, collection}, socket) do
    socket = socket
    |>  Phoenix.Component.update(:collections_by_id, fn collections_by_id ->
          Map.delete(collections_by_id, collection.id)
        end)
    |>  assign(:selected_collection, nil)
    {:noreply, socket}
  end

  defp get_human_readable_time(ms) do
    secs = trunc(ms / 1000)
    remainder = rem(secs, 60)
    minutes = trunc((secs - remainder) / 60)
    "#{minutes}:#{remainder |> Integer.to_string() |> String.pad_leading(2, "0")}"
  end

  def render(assigns) do
    ~H"""
      <div
        id="root"
        class="flex w-full h-full"
        phx-hook="root"
        data-token={@user_token}
      >
        <.modal
          id="device_not_connected"
          closeable={false}
        >
          <div class="h-[36vh] flex flex-col gap-8">
            <div class="text-2xl"> Device Not Connected </div>
          </div>
        </.modal>
        <.modal id="delete_snippet">
          <div
            :if={@snippet_to_delete}
            class="h-[36vh] flex flex-col gap-8"
          >
            <div class="text-2xl"> Delete Snippet </div>
            <div class="flex justify-between">
              <div class="flex-1 flex flex-col gap-8">
                <div class="flex flex-col gap-1">
                  <span> Delete snippet? </span>
                  <span> This cannot be undone. </span>
                </div>
                <div class="flex gap-8">
                  <.button
                    class="w-24"
                    phx-click={"snippet_deleted"}
                  >
                    delete
                  </.button>
                  <.button
                    class="w-24"
                    phx-click={hide_modal("delete_snippet")}
                  >
                    cancel
                  </.button>
                </div>
              </div>
              <div phx-click="snippet_clicked">
                <.snippet_display
                  snippet={@snippet_to_delete}
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

        <.live_component
          module={RepostSnippet}
          :if={@selected_collection}
          id={:repost}
          user_id={@current_user.id}
          collections={Map.values(@collections_by_id)}
          selected_collection={@selected_collection}
          snippet={@snippet_to_repost}
          now_playing_snippet={@now_playing_snippet}
          playing?={@playing?}
          loading?={@loading?}
        />

        <.live_component
          module={AddSnippet}
          :if={@selected_collection}
          id={:create}
          user_token={@user_token}
          user_id={@current_user.id}
          collections={Map.values(@collections_by_id)}
          selected_collection={@selected_collection}
          device_id={@device_id}
          playing?={@playing?}
          player_url={@player_url}
          track_ms={@audio_ms}
        />

        <.live_component
          module={CollectionsIndex}
          id={:show}
          collections_by_id={@collections_by_id}
          selected_collection={@selected_collection}
          current_user={@current_user}
        />

        <div
          :if={@selected_collection}
          class="flex flex-col gap-12 pl-8 w-full"
        >
          <div class="flex flex-col gap-4">
            <div class="flex gap-8 items-end">
              <div class="text-4xl"> <%= @selected_collection.name %> </div>
              <button
                :if={!@selected_collection.is_invite}
                phx-click={show_modal("add_snippet")}
              >
                <.icon name="hero-plus-circle" class="w-8 h-8"/>
              </button>
            </div>
            <div class="max-w-48"> <%= @selected_collection.description %> </div>
          </div>
          <ul
            :if={!@selected_collection.is_invite}
            id="snippets"
            class="flex flex-wrap gap-4"
            phx-hook="snippets"
          >
            <li
              :for={{collection_snippet, i} <- Enum.with_index(@collection_snippets)}
              phx-value-id={collection_snippet.id}
              phx-click="snippet_clicked"
              class={[
                "transition-opacity",
                !@device_id && "opacity-40 cursor-not-allowed"
              ]}
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
              >
                <div>
                  <button
                    phx-click={"repost_snippet_clicked"}
                    phx-value-idx={i}
                    class="opacity-50 transition-opacity hover:opacity-100 pb-1"
                  >
                    <.icon name="hero-plus" class="w-4 h-4" />
                  </button>
                  <button
                    phx-click={"delete_snippet_clicked"}
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
            :if={@selected_collection.is_invite}
            class="flex flex-col h-full justify-center items-center gap-12 pb-16"
          >
            <div class="text-2xl">
              chibi bb invited you to edit this collection
            </div>
            <div class="flex gap-12">
              <.button phx-click="accept_invite_clicked">
                accept invite
              </.button>
              <.button phx-click="reject_invite_clicked">
                reject invite
              </.button>
            </div>
          </div>
        </div>
        <div
         :if={!@selected_collection}
         class="flex justify-center items-center h-full w-full text-2xl pb-16"
        >
          select or create a collection from the sidebar!
        </div>
        <div
          id={"snippet-info-#{@now_playing_snippet.id}"}
          :if={@now_playing_snippet && @now_playing_snippet.collection_id == @selected_collection.id}
          phx-mounted={JS.show(to: "[id^='snippet-info']", transition: {"ease-out-duration-100", "translate-y-16 opacity-0", "translate-y-0 opacity-100"})}
          class="hidden fixed bottom-12 right-12 shadow-2xl rounded-2xl p-8 bg-white transition-transform transition-opacity"
        >
          <div class="flex flex-col gap-4">
            <div class="flex gap-8 justify-between">
              <div
                class="flex-1 cursor-pointer"
                phx-click="track_clicked"
              >
              <.track_display
                track={@now_playing_snippet.snippet.track}
                artist={@now_playing_snippet.snippet.artist}
                thumbnail_url={@now_playing_snippet.snippet.thumbnail_url}
              />
              </div>
              <div class="flex flex-col items-end">
                <div>
                  <%= get_human_readable_time(@now_playing_snippet.snippet.start_ms) %>
                  -
                  <%= get_human_readable_time(@now_playing_snippet.snippet.end_ms) %>
                </div>
                <div class="italic"> added by <%= @now_playing_snippet.added_by.username %> </div>
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
