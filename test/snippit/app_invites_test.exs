defmodule Snippit.AppInvitesTest do
  use Snippit.DataCase

  alias Snippit.AppInvites

  describe "app_invites" do
    alias Snippit.AppInvites.AppInvite

    import Snippit.AppInvitesFixtures

    @invalid_attrs %{}

    test "list_app_invites/0 returns all app_invites" do
      app_invite = app_invite_fixture()
      assert AppInvites.list_app_invites() == [app_invite]
    end

    test "get_app_invite!/1 returns the app_invite with given id" do
      app_invite = app_invite_fixture()
      assert AppInvites.get_app_invite!(app_invite.id) == app_invite
    end

    test "create_app_invite/1 with valid data creates a app_invite" do
      valid_attrs = %{}

      assert {:ok, %AppInvite{} = app_invite} = AppInvites.create_app_invite(valid_attrs)
    end

    test "create_app_invite/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = AppInvites.create_app_invite(@invalid_attrs)
    end

    test "update_app_invite/2 with valid data updates the app_invite" do
      app_invite = app_invite_fixture()
      update_attrs = %{}

      assert {:ok, %AppInvite{} = app_invite} = AppInvites.update_app_invite(app_invite, update_attrs)
    end

    test "update_app_invite/2 with invalid data returns error changeset" do
      app_invite = app_invite_fixture()
      assert {:error, %Ecto.Changeset{}} = AppInvites.update_app_invite(app_invite, @invalid_attrs)
      assert app_invite == AppInvites.get_app_invite!(app_invite.id)
    end

    test "delete_app_invite/1 deletes the app_invite" do
      app_invite = app_invite_fixture()
      assert {:ok, %AppInvite{}} = AppInvites.delete_app_invite(app_invite)
      assert_raise Ecto.NoResultsError, fn -> AppInvites.get_app_invite!(app_invite.id) end
    end

    test "change_app_invite/1 returns a app_invite changeset" do
      app_invite = app_invite_fixture()
      assert %Ecto.Changeset{} = AppInvites.change_app_invite(app_invite)
    end
  end
end
