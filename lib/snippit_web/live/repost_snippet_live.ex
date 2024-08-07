defmodule SnippitWeb.RepostSnippet do
  alias Snippit.Collections.Collection
  alias Snippit.CollectionSnippets.CollectionSnippet
  use SnippitWeb, :live_component

  import SnippitWeb.CustomComponents, warn: false

  alias Snippit.CollectionSnippets
  alias SnippitWeb.AddToCollection

  def mount(socket) do
    socket = socket
      |> assign(:repost_collection, nil)
      |> assign(:error, nil)

    {:ok, socket}
  end

  def update(assigns, socket) do
    case assigns do
      %{snippet: %CollectionSnippet{} = snippet} ->
        socket = socket
        |> assign(:repost_description, snippet.description)
        |> assign(assigns)
        {:ok, socket}
      %{repost_collection: %Collection{}} ->
        socket = socket
        |> assign(:error, nil)
        |> assign(assigns)
        {:ok, socket}
      _ -> {:ok, assign(socket, assigns)}
    end
  end

  def handle_event("description_form_changed", %{"description" => description}, socket) do
    {:noreply, assign(socket, :repost_description, description)}
  end

  def handle_event("snippet_reposted", _, socket) do
    params = %{
      snippet_id: socket.assigns.snippet.snippet.id,
      collection_id: socket.assigns.repost_collection.id,
      description: socket.assigns.repost_description,
      from_collection_id: socket.assigns.selected_collection.id,
      added_by_id: socket.assigns.user_id
    }
    socket = start_async(socket, :snippet_reposted, fn ->
      CollectionSnippets.create_collection_snippet(params)
    end)
    {:noreply, socket}
  end

  def handle_async(:snippet_reposted, {:ok, {:ok, %CollectionSnippet{} = cs}}, socket) do
    socket = socket
      |> assign(:repost_description, nil)
      |> assign(:repost_collection, nil)
      |> push_event("hide_modal", %{"id" => "repost_snippet"})
      |> push_patch(to: ~p"/?collection=#{cs.collection_id}")

    {:noreply, socket}
  end

  def handle_async(:snippet_reposted, {:ok, {:error, changeset}}, socket) do
    error = changeset.errors |> hd() |> elem(1) |> elem(0)
    {:noreply, assign(socket, :error, error)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.modal id="repost_snippet">
        <div
          :if={@snippet}
          class="h-[75vh] flex flex-col gap-8"
        >
          <div class="flex justify-between items-center">
            <div class="text-2xl font-bold"> Add Snippet To Collection </div>
            <div
              :if={@error}
              class="text-red-400 text-sm"
              phx-mounted={JS.transition({"transition-opacity duration-100", "opacity-0", "opacity-100"})}
            >
              <%= @error %>
            </div>
          </div>
          <div class="flex flex-1 justify-between">
            <div class="flex h-full flex-col gap-8 w-64">
              <.form
                phx-change="description_form_changed"
                phx-target={@myself}
              >
                <.input
                  label="Description"
                  name="description"
                  type="textarea"
                  value={@repost_description}
                  phx-debounce={100}
                />
              </.form>
              <div class="flex-1 overflow-hidden">
                <.live_component
                  module={AddToCollection}
                  id={:repost}
                  user_id={@user_id}
                  collections={@collections}
                  selected_collection={@repost_collection}
                  collection_changed={fn collection ->
                    send_update(@myself, repost_collection: collection)
                  end}
                />
              </div>
              <div class="flex gap-8">
                <.button
                  disabled={!@repost_collection}
                  class="w-24"
                  phx-click={"snippet_reposted"}
                  phx-target={@myself}
                >
                  Repost
                </.button>
                <.button
                  class="w-24"
                  kind="secondary"
                  phx-click={hide_modal("repost_snippet")}
                >
                  Cancel
                </.button>
              </div>
            </div>
            <div
              phx-click="snippet_clicked"
              phx-value-id={@snippet.id}
            >
              <.snippet_display
                snippet={@snippet}
                playing?={@now_playing_snippet
                  && @playing?
                  && @snippet.id == @now_playing_snippet.id
                }
                loading?={@now_playing_snippet
                  && @loading?
                  && @snippet.id == @now_playing_snippet.id
                }
              />
            </div>
          </div>
        </div>
      </.modal>
    </div>
    """
  end
end
