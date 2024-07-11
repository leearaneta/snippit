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
      |> assign(:collection_to_delete, nil)

    {:ok, socket}
  end

  def handle_event("collection_clicked", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/?collection=#{id}")}
  end

  def handle_event("add_collection_clicked", _, socket) do
    {:noreply, assign(socket, :adding_collection?, true)}
  end

  def handle_event("discard_collection_clicked", _, socket) do
    collection_form = %Collection{}
      |> Collections.change_form_collection()
      |> to_form()

    socket = socket
      |> assign(:adding_collection?, false)
      |> assign(:collection_form, collection_form)

    {:noreply, socket}
  end

  def handle_event("validate_collection", %{"collection" => collection_params}, socket) do
    collection_form = %Collection{}
      |> Collections.change_form_collection(collection_params)
      |> to_form()

    {:noreply, assign(socket, :collection_form, collection_form)}
  end

  def handle_event("create_collection", %{"collection" => collection_params}, socket) do
    params = collection_params
      |> Map.put("created_by_id", socket.assigns.current_user.id)

    socket = start_async(socket, :create_collection, fn ->
      case Collections.create_collection(params) do
        {:ok, collection} -> collection
        other -> IO.inspect(other)
      end
    end)
    {:noreply, socket}
  end

  def handle_async(:create_collection, {:ok, collection}, socket) do
    blank_collection_form = %Collection{}
    |> Collections.change_form_collection()
    |> to_form()

    send(self(), {:collection_created, collection})

    socket = socket
      |> assign(:adding_collection?, false)
      |> assign(:collection_form, blank_collection_form)
      |> push_patch(to: ~p"/?collection=#{collection.id}")

    {:noreply, socket}
  end

  def handle_event("begin_deleting_collection", %{"idx" => idx}, socket) do
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
      |>  assign(:collection_to_delete, nil)
      |>  push_event("hide_modal", %{"id" => "delete_collection"})

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
      <div class="flex-none w-96 pr-4 flex flex-col gap-6 border-r-2">
        <div class="flex justify-between items-center">
          <div class="text-2xl"> Collections </div>
          <button
            class={[@adding_collection? && "opacity-20 cursor-not-allowed"]}
            phx-click={"add_collection_clicked"}
            phx-target={@myself}
          >
            <.icon name="hero-plus-circle" />
          </button>
        </div>
        <div :if={@adding_collection?}>
          <.form
            phx-change="validate_collection"
            phx-submit="create_collection"
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
                  phx-click="discard_collection_clicked"
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
        <ul
          id="collections"
          phx-hook="collections"
          class="flex-1 flex flex-col gap-2 overflow-scroll"
        >
          <li
            class="collection-link"
            :for={{collection, index} <- Enum.with_index(@collections)}
          >
            <div
              class="cursor-pointer"
              phx-click="collection_clicked"
              phx-target={@myself}
              phx-value-id={collection.id}
            >
              <.collection_display collection={collection}>
                <div>
                  <button
                    :if={length(@collections) > 1}
                    phx-click={"begin_deleting_collection"}
                    phx-value-idx={index}
                    phx-target={@myself}
                    class="opacity-50 transition-opacity hover:opacity-100"
                  >
                    <.icon name="hero-trash" />
                  </button>
                </div>
              </.collection_display>
            </div>
          </li>
        </ul>
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
