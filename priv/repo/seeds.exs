# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Snippit.Repo.insert!(%Snippit.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Snippit.Repo
alias Snippit.Users.User
alias Snippit.Collections.Collection
alias Snippit.AppInvites.AppInvite

%User{
  username: "user 1",
  email: "user_1@snippit.dev",
  spotify_id: "fake spotify id 1"
} |> Repo.insert!()

%User{
  username: "user 2",
  email: "user_2@snippit.dev",
  spotify_id: "fake spotify id 2"
} |> Repo.insert!()

%Collection{
  name: "test",
  description: "test",
  created_by_id: 1
} |> Repo.insert!()

%AppInvite{
  from_user_id: 1,
  email: "lee.araneta@gmail.com",
  collection_id: 1
} |> Repo.insert!()
