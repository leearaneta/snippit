defmodule SnippitWeb.CollectionFormLive do
  use SnippitWeb, :live_component

  import SnippitWeb.CustomComponents, warn: false
  alias Snippit.Collections.Collection
  alias Snippit.Collections
  alias Snippit.Repo

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    collection = Map.get(assigns, :collection, %Collection{})
    collection_form = collection
      |> Collections.change_form_collection()
      |> to_form()

    socket = socket
      |> assign(:collection, collection)
      |> assign(:collection_form, collection_form)
      |> assign(:type, collection.id && :edit || :add)
      |> assign(assigns)

    {:ok, socket}
  end

  def handle_event("validate_collection", %{"collection" => collection_params}, socket) do
    collection_form = %Collection{}
      |> Collections.change_form_collection(collection_params)
      |> to_form()

    {:noreply, assign(socket, :collection_form, collection_form)}
  end

  def handle_event("collection_submitted", %{"collection" => collection_params}, socket) do
    params = collection_params
      |> Map.put("created_by_id", socket.assigns.user_id)

    socket = if socket.assigns.type == :create do
      start_async(socket, :collection_submitted, fn ->
        case Collections.create_collection(params) do
          {:ok, collection} -> collection |> Repo.preload(:created_by)
          other -> IO.inspect(other)
        end
      end)
    else
      collection = socket.assigns.collection
      start_async(socket, :collection_submitted, fn ->
        case Collections.update_collection(collection, params) do
          {:ok, collection} -> collection
          other -> IO.inspect(other)
        end
      end)
    end
    {:noreply, socket}
  end

  def handle_async(:collection_submitted, {:ok, collection}, socket) do
    blank_collection_form = %Collection{}
      |> Collections.change_form_collection()
      |> to_form()

    socket.assigns.collection_submitted.(collection)
    if socket.assigns.type == :edit do
      send(self(), {:collection_edited, collection})
    else
      send(self(), {:collection_created, collection})
    end

    socket = socket
      |> assign(:collection_form, blank_collection_form)

    {:noreply, socket}
  end

  def handle_event("collection_discarded", _, socket) do
    blank_collection_form = %Collection{}
      |> Collections.change_form_collection()
      |> to_form()

    socket.assigns.collection_discarded.()
    {:noreply, assign(socket, :collection_form, blank_collection_form)}
  end

  def render(assigns) do
    ~H"""
      <div class="flex flex-col gap-2">
        <div class="font-bold">
          <%= @type == :edit && "Edit Collection" || "Create Collection" %>
        </div>
        <.form
          phx-change="validate_collection"
          phx-submit="collection_submitted"
          phx-target={@myself}
          as={:collection}
          for={@collection_form}
        >
          <div class="flex gap-4">
            <div class="flex-1 flex flex-col gap-2">
              <.input
                phx-debounce="250"
                label="name"
                field={@collection_form[:name]}
              />
              <.input
                phx-debounce="250"
                label="description"
                type="textarea"
                field={@collection_form[:description]}
              />
            </div>
            <div class="flex flex-col gap-2">
              <button
                type="submit"
                class={[
                  !@collection_form.source.valid? &&
                    "pointer-events-none opacity-20"
                ]}
              >
                <.icon name="hero-check-circle" />
              </button>
              <button
                type="button"
                phx-click="collection_discarded"
                phx-target={@myself}
              >
                <.icon
                  name="hero-minus-circle"
                  class="cursor-pointer"
                />
              </button>
            </div>
          </div>
        </.form>
      </div>
    """
  end
end
