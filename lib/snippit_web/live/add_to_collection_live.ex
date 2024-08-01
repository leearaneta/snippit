defmodule SnippitWeb.AddToCollection do
  import SnippitWeb.CustomComponents, warn: false
  use SnippitWeb, :live_component

  alias Snippit.Collections.Collection
  alias Snippit.Collections

  def mount(socket) do
    collection_form = %Collection{}
      |> Collections.change_form_collection()
      |> to_form()

    socket = socket
      |> assign(:selected_collection, nil)
      |> assign(:creating_collection?, false)
      |> assign(:collection_search, "")
      |> assign(:collection_search_results, [])
      |> assign(:collection_form, collection_form)

    {:ok, socket}
  end

  def handle_event("collection_search", %{"search" => search}, socket) do
    search_results = if search == "" do
      []
    else
      selected_collection = socket.assigns.selected_collection
      socket.assigns.collections
        |>  Enum.filter(fn collection ->
              collection.name |> String.downcase() |> String.contains?(search)
            end)
        |>  Enum.filter(fn collection ->
              if !selected_collection do
                true
              else
                selected_collection.id != collection.id
              end
            end)
    end


    socket = socket
      |> assign(:collection_search, search)
      |> assign(:collection_search_results, search_results)
    {:noreply, socket}
  end

  def handle_event("collection_clicked", %{"id" => id}, socket) do
    collection = Enum.find(socket.assigns.collections, fn collection ->
      collection.id == id
    end)

    socket.assigns.collection_changed.(collection)

    socket = socket
      |> assign(:collection_search, "")
      |> assign(:collection_search_results, [])

    {:noreply, socket}
  end

  def handle_event("create_collection_clicked", _, socket) do
    socket = socket
      |> assign(:selected_collection, nil)
      |> assign(:creating_collection?, true)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
      <div class="flex flex-col overflow-hidden">
        <div
          :if={!@creating_collection?}
          class="flex flex-col gap-1 overflow-hidden"
        >
          <.form>
            <.input
              label="add to collection:"
              type="hidden"
              name="hidden"
              value=""
            />
          </.form>
          <div class="flex flex-col gap-2 overflow-hidden">
            <div :if={@selected_collection} class="flex flex-col">
              <.collection_display collection={@selected_collection} />
            </div>
            <.search
              class="flex-1 overflow-hidden"
              items={@collection_search_results}
              name="collection"
              search={@collection_search}
              el={@myself}
              :let={%{"item" => item}}
            >
              <:pinned_item>
                <button
                  class="h-8 flex items-center gap-2"
                  phx-click={"create_collection_clicked"}
                  phx-target={@myself}
                >
                  <.icon name="hero-plus" class="w-4 h-4" />
                  <span class="font-bold text-sm"> Create New Collection </span>
                </button>
              </:pinned_item>
              <.collection_display collection={item}/>
            </.search>
          </div>
        </div>
        <.live_component
          :if={@creating_collection?}
          id={:add_to_collection}
          type={:create}
          module={SnippitWeb.CollectionFormLive}
          user_id={@user_id}
          collection_submitted={fn collection ->
            @collection_changed.(collection)
            send_update(@myself, creating_collection?: false, selected_collection: collection)
          end}
          collection_discarded={fn ->
            send_update(@myself, creating_collection?: false)
          end}
        />
      </div>
    """
  end
end
