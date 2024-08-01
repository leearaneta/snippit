defmodule Snippit.Collections do
  @moduledoc """
  The Collections context.
  """

  import Ecto.Query, warn: false
  alias Snippit.CollectionUsers
  alias Snippit.CollectionInvites.CollectionInvite
  alias Snippit.AppInvites
  alias Snippit.AppInvites.AppInvite
  alias Snippit.Users
  alias Snippit.CollectionInvites
  alias Snippit.Users.User
  alias Snippit.Repo

  alias Snippit.Collections.Collection
  alias Snippit.CollectionUsers.CollectionUser

  alias Swoosh.Email
  alias Snippit.Mailer

  import Phoenix.Component

  def list_collections do
    Repo.all(Collection)
  end

  def get_collection!(id), do: Repo.get!(Collection, id)

  def create_collection(attrs \\ %{}) do
    %Collection{}
    |> Collection.changeset(attrs)
    |> Repo.insert()
  end

  def update_collection(%Collection{} = collection, attrs) do
    collection
    |> Collection.changeset(attrs)
    |> Repo.update()
  end

  def delete_collection(%Collection{} = collection) do
    Repo.delete(collection)
  end

  def remove_collection(%Collection{} = collection, %User{} = user) do
    from(cu in CollectionUser,
      where: cu.collection_id == ^collection.id,
      where: cu.user_id == ^user.id
    )
    |> Repo.one()
    |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking collection changes.

  ## Examples

      iex> change_collection(collection)
      %Ecto.Changeset{data: %Collection{}}

  """
  def change_form_collection(%Collection{} = collection, attrs \\ %{}) do
    Collection.form_changeset(collection, attrs)
  end

  def change_collection(%Collection{} = collection, attrs \\ %{}) do
    Collection.changeset(collection, attrs)
  end

  defp share_collection_with_existing_user(
    %Collection{} = collection,
    %User{} = from_user,
    %User{} = to_user
  ) do
    if collection.created_by_id != to_user.id do
      existing_collection_user = Ecto.Query.from(cu in CollectionUser,
        where: cu.user_id == ^to_user.id,
        where: cu.collection_id == ^collection.id
      ) |> Repo.one()
      if !existing_collection_user do
        payload = %{
          collection_id: collection.id,
          from_user_id: from_user.id,
          user_id: to_user.id
        }
        case CollectionInvites.create_collection_invite(payload) do
          {:ok, _} -> deliver_collection_shared_email(to_user.email, from_user, collection)
          {:error, _} -> nil
        end
      end
    end
  end

  defp share_collection_with_email(
    %Collection{} = collection,
    %User{} = from_user,
    email_to_invite
  ) do
    existing_user = Users.get_user_by_email(email_to_invite)
    if existing_user do
      share_collection_with_existing_user(
        collection,
        from_user,
        existing_user
      )
    else
      payload = %{
        collection_id: collection.id,
        from_user_id: from_user.id,
        email: email_to_invite
      }
      case AppInvites.create_app_invite(payload) do
        {:ok, _} ->
          deliver_collection_shared_email(email_to_invite, from_user, collection)
        {:error, _} -> nil
      end
    end
  end

  def share_collection(
    %Collection{} = collection,
    %User{} = current_user,
    users_to_share_with,
    emails_to_invite
  ) do
    Repo.transaction(fn ->
      collection_invite_tasks = users_to_share_with
      |>  Enum.map(fn user_to_share_with ->
            Task.async(fn ->
              share_collection_with_existing_user(
                collection,
                current_user,
                user_to_share_with
              )
            end)
          end)

      app_invite_tasks = emails_to_invite
      |>  Enum.map(fn email_to_invite ->
            Task.async(fn ->
              share_collection_with_email(
                collection,
                current_user,
                email_to_invite
              )
            end)
          end)

      Task.await_many(collection_invite_tasks ++ app_invite_tasks)
    end)
  end

  def get_collections_query(%User{} = current_user) do
    is_editor_query = from cu in CollectionUser,
      where: cu.user_id == ^current_user.id,
      where: cu.is_editor == true

    from c in Collection,
      left_join: cu in assoc(c, :collection_users),
      left_join: u in assoc(cu, :user),
      left_join: cu_ in subquery(is_editor_query), on: cu_.collection_id == c.id,
      where: u.id == ^current_user.id or c.created_by_id == ^current_user.id,
      preload: [:created_by],
      preload: [collection_users: {cu, user: u}],
      select: %{c | is_editor: cu_.is_editor}
  end

  def get_collection_invites_query(%User{} = current_user) do
    from c in Collection,
      inner_join: ci in assoc(c, :collection_invites), on: ci.user_id == ^current_user.id,
      inner_join: u in assoc(ci, :from_user),
      preload: [:created_by],
      preload: [collection_invites: {ci, from_user: u}],
      select: %{c | invited_by: u}
  end

  defp delete_all_collection_invites(%Collection{} = collection) do
    collection_invite = hd(collection.collection_invites)
    from(ci in CollectionInvite,
      where: ci.user_id == ^collection_invite.user_id,
      where: ci.collection_id == ^collection_invite.collection_id
    ) |> Repo.delete_all()
  end

  def accept_invite(%Collection{} = collection) do
    collection_invite = hd(collection.collection_invites)
    Repo.transaction(fn ->
      delete_all_collection_invites(collection)
      {:ok, _} = CollectionUsers.create_collection_user(%{
        collection_id: collection.id,
        user_id: collection_invite.user_id,
        is_editor: true
      })
    end)
  end

  def reject_invite(%Collection{} = collection) do
    delete_all_collection_invites(collection)
    {:ok, true}
  end

  defp email_layout(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <style>
          body {
            font-family: system-ui, sans-serif;
            margin: 3em auto;
            overflow-wrap: break-word;
            word-break: break-all;
            max-width: 1024px;
            padding: 0 1em;
          }
        </style>
      </head>
      <body>
        <%= render_slot(@inner_block) %>
      </body>
    </html>
    """
  end

  def collection_shared_content(assigns) do
    base_url = SnippitWeb.Endpoint.url()
    collection_url = URI.merge(base_url, "?collection=#{assigns.collection.id}")
    assigns = Map.put(assigns, :collection_url, collection_url)
    ~H"""
    <.email_layout>
      <p>Hi,</p>

      <p><%= @username %> shared a collection "<%= @collection.name %>" with you! </p>

      <a href={@collection_url}>Listen on Snippit</a>
    </.email_layout>
    """
  end

  def deliver_collection_shared_email(to_email, %User{} = from_user, %Collection{} = collection) do
    template = collection_shared_content(%{username: from_user.username, collection: collection})
    html = heex_to_html(template)
    text = html_to_text(html)
    email =
      Email.new()
      |> Email.to(to_email)
      |> Email.from({"Snippit", "hello@snippit.studio"})
      |> Email.subject("Collection shared with you: \"#{collection.name}\"")
      |> Email.html_body(html)
      |> Email.text_body(text)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  defp heex_to_html(template) do
    template
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp html_to_text(html) do
    html
    |> Floki.parse_document!()
    |> Floki.find("body")
    |> Floki.text(sep: "\n\n")
  end

end
