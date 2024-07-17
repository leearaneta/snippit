defmodule SnippitWeb.HomeLive do
  alias Snippit.CollectionSnippets
  alias SnippitWeb.CustomComponents
  alias SnippitWeb.CollectionsIndex

  alias SnippitWeb.AddSnippet
  alias SnippitWeb.RepostSnippet
  alias Snippit.CollectionSnippets.CollectionSnippet
  alias Snippit.Repo
  alias SnippitWeb.AddToCollection

  alias Snippit.SpotifyApi

  import CustomComponents, warn: false
  import Ecto.Query, warn: false

  use SnippitWeb, :live_view
  on_mount {SnippitWeb.UserAuth, :ensure_authenticated}

  def mount(params, session, socket) do
    collections = Ecto.assoc(socket.assigns.current_user, :collections) |> Repo.all()

    socket = socket
      |> assign(:collections, collections)
      |> load_selected_collection(params, collections)
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

  defp load_selected_collection(socket, params, collections) do
    if Map.get(socket.assigns, :selected_collection) do
      CollectionSnippets.unsubscribe(socket.assigns.selected_collection.id)
    end

    selected_collection =
      if collection_id = params["collection"] do
        collection_id = String.to_integer(collection_id)
        collection = Enum.find(collections, fn collection ->
          collection.id === collection_id
        end)
      else
        hd(collections)
      end

    if selected_collection do
      CollectionSnippets.subscribe(selected_collection.id)
      socket
        |> assign(:selected_collection, selected_collection)
        |> assign(:collection_snippets, [])
        |> start_async(:load_collection_snippets, fn ->
          from(cs in CollectionSnippet,
            where: cs.collection_id == ^selected_collection.id,
            preload: [:snippet]
          )
          |> Repo.all()
        end)
    else
      socket
        |> put_flash(:error, "sorry, we can't find that collection.")
        |> push_navigate(to: ~p"/")
    end
  end

  def handle_async(:load_collection_snippets, {:ok, collection_snippets}, socket) do
    {:noreply, assign(socket, :collection_snippets, collection_snippets)}
  end

  def handle_params(params, _, socket) do
    {:noreply, load_selected_collection(socket, params, socket.assigns.collections) }
  end

  def handle_event("player_ready", device_id, socket) do
    SpotifyApi.set_device_id(socket.assigns.user_token, device_id)
    socket = socket
      |> assign(:device_id, device_id)
      |> put_flash(:info, "audio player ready!")
    {:noreply, socket}
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
    snippet = socket.assigns.collection_snippets
      |> Enum.find(fn cs -> cs.id == String.to_integer(id) end)
    socket = socket
      |> assign(:now_playing_snippet, snippet)
      |> play_snippet(snippet)
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
      [collection_snippet | collection_snippets]
    end)

    {:noreply, socket}
  end

  def handle_info({:collection_created, collection}, socket) do
    socket = socket
      |>  Phoenix.Component.update(:collections, fn collections ->
            [collection | collections]
          end)
      |>  push_patch(to: ~p"/?collection=#{collection.id}")

    {:noreply, socket}
  end

  def handle_info({:collection_edited, edited_collection}, socket) do
    socket = socket
      |>  Phoenix.Component.update(:collections, fn collections ->
            Enum.map(collections, fn collection ->
              if collection.id == edited_collection.id do
                edited_collection
              else
                collection
              end
            end)
          end)

    {:noreply, socket}
  end

  def handle_info({:collection_deleted, collection_id}, socket) do
    socket = Phoenix.Component.update(socket, :collections, fn collections ->
      Enum.filter(collections, fn collection ->
        collection.id != collection_id
      end)
    end)
    if socket.assigns.selected_collection.id == collection_id do
      new_collection_id = hd(socket.assigns.collections).id
      {:noreply, push_patch(socket, to: ~p"/?collection=#{new_collection_id}")}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
      <div
        id="root"
        class="flex w-full h-full"
        phx-hook="root"
        data-token={@user_token}
      >
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
          playing?={@playing?}
          player_url={@player_url}
          track_ms={@audio_ms}
        />

        <.live_component
          module={CollectionsIndex}
          id={:show}
          user_id={@current_user.id}
          collections={@collections}
          selected_collection={@selected_collection}
          current_user={@current_user}
        />

        <div class="flex flex-col gap-12 pl-8 w-full">
          <div class="flex flex-col gap-4">
            <div class="flex gap-8 items-end">
              <div class="text-4xl"> <%= @selected_collection.name %> </div>
              <button phx-click={show_modal("add_snippet")}>
                <.icon name="hero-plus-circle" class="w-8 h-8"/>
              </button>
            </div>
            <div class="max-w-48"> <%= @selected_collection.description %> </div>
          </div>
          <ul
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
        </div>
      </div>
    """
  end
end
