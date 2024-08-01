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

Enum.each(1..25, fn idx ->
  %User{
    username: "user #{idx} ooooooooohhhhhhh yeeaaaaaaaaaahhhhhhh",
    email: "user_#{idx}@snippit.dev",
    spotify_id: "fake spotify id #{idx}"
  } |> Repo.insert!()

  IO.inspect(idx)
  %Collection{
    name: "test",
    description: "test",
    created_by_id: idx
  } |> Repo.insert!()

  %AppInvite{
    from_user_id: idx,
    email: "lee.araneta@gmail.com",
    collection_id: idx
  } |> Repo.insert!()
end)
