defmodule Snippit.CollectionInvitesTest do
  use Snippit.DataCase

  alias Snippit.CollectionInvites

  describe "collection_invites" do
    alias Snippit.CollectionInvites.CollectionInvite

    import Snippit.CollectionInvitesFixtures

    @invalid_attrs %{}

    test "list_collection_invites/0 returns all collection_invites" do
      collection_invite = collection_invite_fixture()
      assert CollectionInvites.list_collection_invites() == [collection_invite]
    end

    test "get_collection_invite!/1 returns the collection_invite with given id" do
      collection_invite = collection_invite_fixture()
      assert CollectionInvites.get_collection_invite!(collection_invite.id) == collection_invite
    end

    test "create_collection_invite/1 with valid data creates a collection_invite" do
      valid_attrs = %{}

      assert {:ok, %CollectionInvite{} = collection_invite} = CollectionInvites.create_collection_invite(valid_attrs)
    end

    test "create_collection_invite/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = CollectionInvites.create_collection_invite(@invalid_attrs)
    end

    test "update_collection_invite/2 with valid data updates the collection_invite" do
      collection_invite = collection_invite_fixture()
      update_attrs = %{}

      assert {:ok, %CollectionInvite{} = collection_invite} = CollectionInvites.update_collection_invite(collection_invite, update_attrs)
    end

    test "update_collection_invite/2 with invalid data returns error changeset" do
      collection_invite = collection_invite_fixture()
      assert {:error, %Ecto.Changeset{}} = CollectionInvites.update_collection_invite(collection_invite, @invalid_attrs)
      assert collection_invite == CollectionInvites.get_collection_invite!(collection_invite.id)
    end

    test "delete_collection_invite/1 deletes the collection_invite" do
      collection_invite = collection_invite_fixture()
      assert {:ok, %CollectionInvite{}} = CollectionInvites.delete_collection_invite(collection_invite)
      assert_raise Ecto.NoResultsError, fn -> CollectionInvites.get_collection_invite!(collection_invite.id) end
    end

    test "change_collection_invite/1 returns a collection_invite changeset" do
      collection_invite = collection_invite_fixture()
      assert %Ecto.Changeset{} = CollectionInvites.change_collection_invite(collection_invite)
    end
  end
end
