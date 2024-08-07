defmodule SnippitWeb.CollectionsLive do
  alias Snippit.Users
  use SnippitWeb, :live_component

  import SnippitWeb.CustomComponents, warn: false
  import Ecto.Changeset

  alias Snippit.Collections.Collection
  alias Snippit.Collections
  alias Snippit.AppInvites.AppInvite
  alias Snippit.AppInvites

  def mount(socket) do
    app_invite_form = %AppInvite{}
      |> AppInvites.change_app_invite_form()
      |> to_form()

    socket = socket
    |> assign(:adding_collection?, false)
    |> assign(:collection_to_edit, nil)
    |> assign(:collection_to_delete, nil)
    |> assign(:collection_search, "")
    |> assign(:collection_search_results, [])
    |> assign(:collection_to_share, nil)
    |> assign(:user_search, "")
    |> assign(:user_search_results, [])
    |> assign(:users_to_share_with, [])
    |> assign(:app_invite_form, app_invite_form)
    |> assign(:emails_to_invite, [])

    {:ok, socket}
  end

  def handle_event("collection_clicked", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/?collection=#{id}")}
  end

  def handle_event("add_collection_clicked", _, socket) do
    {:noreply, assign(socket, :adding_collection?, true)}
  end

  def handle_event("edit_collection_clicked", %{"id" => id}, socket) do
    collection = Map.get(socket.assigns.collections_by_id, String.to_integer(id))
    {:noreply, assign(socket, :collection_to_edit, collection)}
  end

  def handle_event("delete_collection_clicked", %{"id" => id}, socket) do
    collection = Map.get(socket.assigns.collections_by_id, String.to_integer(id))
    socket = socket
    |> assign(:collection_to_delete, collection)
    |> push_event("show_modal", %{"id" => "delete_collection"})

    {:noreply, socket}
  end

  def handle_event("share_collection_clicked", %{"id" => id}, socket) do
    collection = Map.get(socket.assigns.collections_by_id, String.to_integer(id))
    socket = socket
    |> assign(:collection_to_share, collection)
    |> push_event("show_modal", %{"id" => "share_collection"})

    {:noreply, socket}
  end

  def handle_event("collection_shared", _, socket) do
    %{
      collection_to_share: collection_to_share,
      current_user: current_user,
      users_to_share_with: users_to_share_with,
      emails_to_invite: emails_to_invite
    } = socket.assigns
    socket = start_async(socket, :share_collection, fn ->
      case Collections.share_collection(
        collection_to_share,
        current_user,
        users_to_share_with,
        emails_to_invite
      ) do
        {:ok, _} -> collection_to_share
        {:error, error} -> IO.inspect(error)
      end
    end)
    {:noreply, socket}
  end

  def handle_async(:share_collection, {:ok, %Collection{} = _}, socket) do
    socket = socket
    |> assign(:emails_to_invite, [])
    |> assign(:users_to_share_with, [])
    |> assign(:user_search_results, [])
    |> assign(:user_search, "")
    |> put_flash(:info, "collection successfully shared!")
    |> push_event("hide_modal", %{"id" => "share_collection"})

    {:noreply, socket}
  end

  def handle_event("user_search", form, socket) do
    search = form["search"]
    user_id = socket.assigns.current_user.id
    ids_to_omit = [user_id]
    socket = start_async(socket, :load_user_search_results, fn ->
      Users.search_users_by_username(search, ids_to_omit)
    end)
    {:noreply, socket}
  end

  def handle_async(:load_user_search_results, {:ok, user_search_results}, socket) do
    user_search_results = MapSet.new(user_search_results)
      |> MapSet.difference(MapSet.new(socket.assigns.users_to_share_with))
    {:noreply, assign(socket, :user_search_results, user_search_results)}
  end

  def handle_event("user_clicked", %{"id" => id}, socket) do
    clicked_user = socket.assigns.user_search_results
      |> Enum.find(fn user -> user.id == id end)

    users_to_share_with = socket.assigns.users_to_share_with ++ [clicked_user]
    socket = socket
      |> assign(:users_to_share_with, users_to_share_with)
      |> assign(:user_search_results, [])

    {:noreply, socket}
  end

  def handle_event("deselect_user_clicked", %{"id" => id}, socket) do
    users_to_share_with = socket.assigns.users_to_share_with
      |> Enum.filter(fn user -> user.id != String.to_integer(id) end)

    {:noreply, assign(socket, :users_to_share_with, users_to_share_with)}
  end

  defp validate_no_duplicate_emails(changeset, emails) do
    if !Enum.at(changeset.errors, 0)
      && Enum.find(emails, fn email -> get_field(changeset, :email) == email end) do
      add_error(changeset, :_, "you can't invite someone twice")
    else
      changeset
    end
  end

  defp validate_no_inviting_self(changeset, current_user) do
    if !Enum.at(changeset.errors, 0)
      && get_field(changeset, :email) == current_user.email  do
      add_error(changeset, :_, "you can't invite yourself!")
    else
      changeset
    end
  end

  def handle_event("validate_app_invite", %{"app_invite" => app_invite_params}, socket) do
    app_invite_form = %AppInvite{}
    |> AppInvites.change_app_invite_form(app_invite_params)
    |> validate_no_duplicate_emails(socket.assigns.emails_to_invite)
    |> validate_no_inviting_self(socket.assigns.current_user)
    |> to_form()

    {:noreply, assign(socket, :app_invite_form, app_invite_form)}
  end

  def handle_event("invite_user_clicked", %{"app_invite" => app_invite}, socket) do
    emails_to_invite = socket.assigns.emails_to_invite ++ [app_invite["email"]]
    app_invite_form = %AppInvite{}
    |> AppInvites.change_app_invite_form()
    |> to_form()

    socket = socket
    |> assign(:emails_to_invite, emails_to_invite)
    |> assign(:app_invite_form, app_invite_form)

    {:noreply, socket}
  end

  def handle_event("deselect_email_clicked", %{"email" => clicked_email}, socket) do
    emails_to_invite = socket.assigns.emails_to_invite
    |> Enum.filter(fn email -> email != clicked_email end)

    {:noreply, assign(socket, :emails_to_invite, emails_to_invite)}
  end

  def handle_event("delete_collection", _, socket) do
    collection = socket.assigns.collection_to_delete
    current_user = socket.assigns.current_user
    socket = start_async(socket, :delete_collection, fn ->
      result = if collection.created_by_id == current_user.id do
        Collections.delete_collection(collection)
      else
        Collections.remove_collection(collection, current_user)
      end
      case result do
        {:ok, _} -> collection.id
        {:error, error} -> IO.inspect(error)
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
    search_results = socket.assigns.collections_by_id
    |>  Map.values()
    |>  Enum.filter(fn collection ->
          collection.name |> String.downcase() |> String.contains?(search)
        end)
    socket = socket
    |> assign(:collection_search, search)
    |> assign(:collection_search_results, search_results)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
      <div
        id="collections"
        class="flex-none w-96 pr-4 flex flex-col gap-6 border-r-2"
      >
        <div class="flex justify-between items-center">
          <div class="text-2xl font-bold"> Collections </div>
          <button
            class={[@adding_collection? || @collection_to_edit && "opacity-20 cursor-not-allowed"]}
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
          type={:create}
          user_id={@current_user.id}
          collection_submitted={fn _ -> send_update(@myself, adding_collection?: false) end}
          collection_discarded={fn -> send_update(@myself, adding_collection?: false) end}
        />
        <.live_component
          :if={@collection_to_edit}
          id={:edit_collection}
          module={SnippitWeb.CollectionFormLive}
          collection={@collection_to_edit}
          user_id={@current_user.id}
          collection_submitted={fn _ -> send_update(@myself, collection_to_edit: nil) end}
          collection_discarded={fn -> send_update(@myself, collection_to_edit: nil) end}
        />
        <.search
          :if={!@adding_collection? && !@collection_to_edit}
          id="collections-index"
          phx-hook="collections_index"
          class="flex-1"
          items={@collection_search == ""
            && @collections_by_id |> Map.values()
            || @collection_search_results
          }
          name="collection"
          search={@collection_search}
          el={@myself}
          :let={%{"item" => collection}}
        >
          <.collection_display
            class={"collection-link"}
            collection={collection}
          >
            <div :if={!collection.invited_by}>
              <button
                :if={collection.created_by_id == @current_user.id}
                phx-click={"edit_collection_clicked"}
                phx-value-id={collection.id}
                phx-target={@myself}
                class="opacity-50 transition-opacity hover:opacity-100"
              >
                <.icon name="hero-pencil-square" />
              </button>
              <button
                :if={collection.created_by_id == @current_user.id}
                phx-click={"share_collection_clicked"}
                phx-value-id={collection.id}
                phx-target={@myself}
                class="opacity-50 transition-opacity hover:opacity-100"
              >
                <.icon name="hero-share" />
              </button>
              <button
                phx-click={"delete_collection_clicked"}
                phx-value-id={collection.id}
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
            <div class="text-2xl">
              <%=
                @collection_to_delete.created_by_id == @current_user.id
                && "Delete" || "Remove"
              %>
              Collection
            </div>
            <div class="flex justify-between">
              <div class="flex-1 flex flex-col gap-8">
                <div class="flex flex-col gap-1">
                  <span>
                    <%=
                      @collection_to_delete.created_by_id == @current_user.id
                      && "Delete" || "Remove"
                    %>
                    collection?
                  </span>
                  <span> This cannot be undone. </span>
                </div>
                <div class="flex gap-8">
                  <.button
                    class="w-24"
                    kind="warning"
                    phx-click={"delete_collection"}
                    phx-target={@myself}
                  >
                    Delete
                  </.button>
                  <.button
                    class="w-24"
                    kind="secondary"
                    phx-click={hide_modal("delete_collection")}
                  >
                    Cancel
                  </.button>
                </div>
              </div>
              <.collection_display
                collection={@collection_to_delete}
                class="flex-1 max-w-[50%]"
              />
            </div>
          </div>
        </.modal>
        <.modal id="share_collection">
          <div
            :if={@collection_to_share}
            class="h-[64vh] flex flex-col gap-8"
          >
            <div class="text-2xl font-bold"> Share Collection </div>
            <div class="h-full flex justify-between gap-16 overflow-hidden">
              <div class="flex-1 flex flex-col gap-8">
                <div class="flex-1 flex flex-col gap-1 overflow-hidden">
                  <.form
                    for={@app_invite_form}
                    phx-change="validate_app_invite"
                    phx-submit="invite_user_clicked"
                    phx-target={@myself}
                  >
                    <div class="flex gap-2 items-end">
                      <.input
                        input_class="h-10"
                        icon="hero-envelope"
                        field={@app_invite_form[:email]}
                        label="Invite via email:"
                        phx-debounce="250"
                      />
                      <.button
                        class="h-10"
                        disabled={!@app_invite_form.source.valid?}
                      >
                        invite
                      </.button>
                    </div>
                  </.form>
                  <div class="relative flex py-2 items-center">
                    <div class="flex-grow border-t border-gray-400"></div>
                    <span class="flex-shrink mx-4">OR</span>
                    <div class="flex-grow border-t border-gray-400"></div>
                  </div>
                  <.search
                    name="user"
                    items={@user_search_results}
                    search={@user_search}
                    el={@myself}
                    label="Search by username:"
                    :let={%{"item" => user}}
                  >
                    <div>
                      <%= user.username %>
                    </div>
                  </.search>
                </div>
                <div class="flex gap-8">
                  <.button
                    class="w-24"
                    phx-click={"collection_shared"}
                    phx-target={@myself}
                  >
                    Share
                  </.button>
                  <.button
                    class="w-24"
                    kind="secondary"
                    phx-click={hide_modal("share_collection")}
                  >
                    Cancel
                  </.button>
                </div>
              </div>
              <div class="flex-1 flex flex-col gap-8 max-w-[50%]">
                <.collection_display collection={@collection_to_share} />
                <div class="flex flex-col gap-2 overflow-hidden">
                  <ul class="flex flex-col gap-1 overflow-scroll">
                    <li
                      :for={user <- @users_to_share_with}
                      class="flex justify-between"
                    >
                      <div class="flex items-center gap-2">
                        <%= user.username %>
                      </div>
                      <div
                        class="cursor-pointer"
                        phx-value-id={user.id}
                        phx-click="deselect_user_clicked"
                        phx-target={@myself}
                      >
                        <.icon name="hero-x-mark-solid" />
                      </div>
                    </li>
                    <li
                      :for={email <- @emails_to_invite}
                      class="flex justify-between"
                    >
                      <div class="flex items-center gap-2">
                        <.icon name="hero-envelope" />
                        <%= email %>
                      </div>
                      <div
                        class="cursor-pointer"
                        phx-value-email={email}
                        phx-click="deselect_email_clicked"
                        phx-target={@myself}
                      >
                        <.icon name="hero-x-mark-solid" />
                      </div>
                    </li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </.modal>
      </div>
    """
  end
end
