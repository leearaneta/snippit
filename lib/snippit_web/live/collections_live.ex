defmodule SnippitWeb.CollectionsIndex do
  use SnippitWeb, :live_component

  import SnippitWeb.CustomComponents, warn: false
  alias Snippit.Collections.Collection
  alias Snippit.Collections

  def mount(socket) do
    collection_form = %Collection{}
      |> Collections.change_form_collection()
      |> to_form()

    socket = socket
      |> assign(:collection_form, collection_form)
      |> assign(:adding_collection?, false)
      |> assign(:editing_collection, nil)
      |> assign(:collection_to_delete, nil)
      |> assign(:collection_search, "")
      |> assign(:collection_search_results, [])

    {:ok, socket}
  end

  def handle_event("collection_clicked", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/?collection=#{id}")}
  end

  def handle_event("add_collection_clicked", _, socket) do
    {:noreply, assign(socket, :adding_collection?, true)}
  end

  def handle_event("edit_collection_clicked", %{"idx" => idx}, socket) do
    collection = Enum.at(socket.assigns.collections, String.to_integer(idx))
    {:noreply, assign(socket, :editing_collection, collection)}
  end

  def handle_event("delete_collection_clicked", %{"idx" => idx}, socket) do
    collection = Enum.at(socket.assigns.collections, String.to_integer(idx))
    socket = socket
      |> assign(:collection_to_delete, collection)
      |> push_event("show_modal", %{"id" => "delete_collection"})

    {:noreply, socket}
  end

  def handle_event("delete_collection", _, socket) do
    collection = socket.assigns.collection_to_delete
    socket = start_async(socket, :delete_collection, fn ->
      case Collections.delete_collection(collection) do
        {:ok, _} -> collection.id
        other -> IO.inspect(other)
      end
    end)
    {:noreply, socket}
  end

  def handle_async(:delete_collection, {:ok, collection_id}, socket) do
    send(self(), {:collection_deleted, collection_id})

    socket = socket
      |> assign(:collection_to_delete, nil)
      |> push_event("hide_modal", %{"id" => "delete_collection"})

    {:noreply, socket}
  end

  def handle_event("collection_search", %{"search" => search}, socket) do
    IO.inspect(search)
    search_results = Enum.filter(socket.assigns.collections, fn collection ->
      collection.name |> String.downcase() |> String.contains?(search)
    end)
    socket = socket
      |> assign(:collection_search, search)
      |> assign(:collection_search_results, search_results)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
      <div class="flex-none w-96 pr-4 flex flex-col gap-6 border-r-2">
        <div class="flex justify-between items-center">
          <div class="text-2xl"> Collections </div>
          <button
            class={[@adding_collection? || @editing_collection && "opacity-20 cursor-not-allowed"]}
            phx-click={"add_collection_clicked"}
            phx-target={@myself}
          >
            <.icon name="hero-plus-circle" />
          </button>
        </div>
        <.live_component
          :if={@adding_collection?}
          id={:create_collection}
          module={SnippitWeb.CollectionFormLive}
          user_id={@user_id}
          collection_submitted={fn _ -> send_update(@myself, adding_collection?: false) end}
          collection_discarded={fn -> send_update(@myself, adding_collection?: false) end}
        />
        <.live_component
          :if={@editing_collection}
          id={:edit_collection}
          module={SnippitWeb.CollectionFormLive}
          collection={@editing_collection}
          user_id={@user_id}
          collection_submitted={fn _ -> send_update(@myself, editing_collection: nil) end}
          collection_discarded={fn -> send_update(@myself, editing_collection: nil) end}
        />
        <.search
          :if={!@adding_collection? && !@editing_collection}
          id="collections"
          phx-hook="collections"
          class="flex-1"
          items={@collection_search == "" && @collections || @collection_search_results}
          name="collection"
          search={@collection_search}
          el={@myself}
          :let={%{"item" => collection, "index" => index}}
        >
          <.collection_display
            class="collection-link"
            collection={collection}
          >
            <div>
              <button
                phx-click={"edit_collection_clicked"}
                phx-value-idx={index}
                phx-target={@myself}
                class="opacity-50 transition-opacity hover:opacity-100"
              >
                <.icon name="hero-pencil-square" />
              </button>
              <button
                :if={length(@collections) > 1}
                phx-click={"delete_collection_clicked"}
                phx-value-idx={index}
                phx-target={@myself}
                class="opacity-50 transition-opacity hover:opacity-100"
              >
                <.icon name="hero-trash" />
              </button>
            </div>
          </.collection_display>
        </.search>
        <.modal id="delete_collection">
          <div
            :if={@collection_to_delete}
            class="h-[25vh] flex flex-col gap-8"
          >
            <div class="text-2xl"> Delete Collection </div>
            <div class="flex justify-between">
              <div class="flex-1 flex flex-col gap-8">
                <div class="flex flex-col gap-1">
                  <span> Delete collection? </span>
                  <span> This cannot be undone. </span>
                </div>
                <div class="flex gap-8">
                  <.button
                    class="w-24"
                    phx-click={"delete_collection"}
                    phx-target={@myself}
                  >
                    delete
                  </.button>
                  <.button
                    class="w-24"
                    phx-click={hide_modal("delete_collection")}
                  >
                    cancel
                  </.button>
                </div>
              </div>
              <.collection_display
                collection={@collection_to_delete}
                class="flex-1"
              />
            </div>
          </div>
        </.modal>
      </div>
    """
  end
end
