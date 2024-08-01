defmodule SnippitWeb.HomeLive do
  alias SnippitWeb.SnippetsLive
  alias Snippit.Collections
  alias Snippit.CollectionSnippets
  alias SnippitWeb.CustomComponents
  alias SnippitWeb.CollectionsLive


  alias Snippit.CollectionSnippets.CollectionSnippet
  alias Snippit.Repo


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

  defp reset_audio_state(socket) do
    socket
    |> assign(:player_url, nil)
    |> assign(:playing?, false)
  end

  def handle_event("track_clicked", %{"url" => url}, socket) do
    socket = socket
    |> reset_audio_state()
    |> push_event("track_clicked", %{"url" => url})
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

  def handle_info({:snippet_created, collection_snippet}, socket) do
    socket = Phoenix.Component.update(socket, :collection_snippets, fn collection_snippets ->
      [Repo.preload(collection_snippet, :added_by) | collection_snippets]
    end)

    {:noreply, socket}
  end

  def handle_info({:collection_created, collection}, socket) do
    collection = Repo.preload(collection, :created_by)
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
    socket = if edited_collection.id == socket.assigns.selected_collection.id do
      assign(socket, :selected_collection, edited_collection)
    else
      socket
    end
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

  def handle_event("failed_to_authenticate", _, socket) do
    {:noreply, redirect(socket, to: ~p"/auth/logout")}
  end

  def render(assigns) do
    ~H"""
      <div
        id="root"
        class="flex w-full h-full"
        phx-hook="root"
        data-token={@user_token}
      >
        <.live_component
          module={CollectionsLive}
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
              <div class="text-4xl max-w-96"> <%= @selected_collection.name %> </div>
              <div class="flex items-center gap-4">
                <button
                  :if={!@selected_collection.invited_by}
                  phx-click={show_modal("add_snippet")}
                >
                  <.icon name="hero-plus-circle" class="w-8 h-8"/>
                </button>
                <button
                  :if={@selected_collection.created_by_id == @current_user.id}
                  phx-click={"edit_collection_clicked"}
                  phx-value-id={@selected_collection.id}
                  phx-target="#collections"
                  class="opacity-50 transition-opacity hover:opacity-100"
                >
                  <.icon name="hero-pencil-square" />
                </button>
                <button
                  :if={@selected_collection.created_by_id == @current_user.id}
                  phx-click={"share_collection_clicked"}
                  phx-value-id={@selected_collection.id}
                  phx-target="#collections"
                  class="opacity-50 transition-opacity hover:opacity-100"
                >
                  <.icon name="hero-share" />
                </button>
                <button
                  phx-click={"delete_collection_clicked"}
                  phx-value-id={@selected_collection.id}
                  phx-target="#collections"
                  class="opacity-50 transition-opacity hover:opacity-100"
                >
                  <.icon name="hero-trash" />
                </button>
              </div>
            </div>
            <div class="flex justify-between">
              <div class="max-w-xl">
                <%= @selected_collection.description %>
              </div>
              <div class="max-w-96 whitespace-nowrap text-ellipsis overflow-hidden">
                created by <%= @selected_collection.created_by.username %>
              </div>
            </div>
          </div>
          <.live_component
            module={SnippetsLive}
            :if={@selected_collection && !@selected_collection.invited_by}
            id={:snippets}
            collections={Map.values(@collections_by_id)}
            collection_snippets={@collection_snippets}
            selected_collection={@selected_collection}
            current_user={@current_user}
            user_token={@user_token}
            audio_ms={@audio_ms}
            player_url={@player_url}
            device_id={@device_id}
            playing?={@playing?}
            loading?={@loading?}
          />
          <div
            :if={@selected_collection.invited_by}
            class="flex flex-col h-full justify-center items-center gap-12 pb-16"
          >
            <div class="text-2xl">
              <%= @selected_collection.invited_by.username %> invited you to edit this collection
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
      </div>
    """
  end
end
