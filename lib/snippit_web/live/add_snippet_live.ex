defmodule SnippitWeb.AddSnippet do
  use SnippitWeb, :live_component

  import SnippitWeb.CustomComponents, warn: false
  import Ecto.Changeset

  alias SnippitWeb.AddToCollection

  alias Snippit.Snippets
  alias Snippit.SpotifyApi

  def mount(socket) do
    snippet_search_form = %{"track" => "", "artist" => "", "album" => ""}
    |> to_form()

    socket = socket
    |> assign(:snippet_search_form, snippet_search_form)
    |> assign(:track_search_results, [])
    |> assign(:selected_track, nil)
    |> assign(:start_ms, 0)
    |> assign(:track_ms, 0)
    |> assign(:end_ms, nil)
    |> assign(:track_width_px, 0)
    |> assign(:collection_to_associate, nil)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = if Map.get(assigns, :selected_collection) do
      assign(socket, :collection_to_associate, assigns.selected_collection)
    else
      socket
    end

    {:ok, assign(socket, assigns)}
  end

  def handle_event("search_form_change", form, socket) do
    user_token = socket.assigns.user_token
    socket = socket
    |>  start_async(:load_track_search_results, fn ->
          SpotifyApi.search_tracks(user_token, form)
        end)
    |>  assign(:snippet_search_form, form |> to_form())
    {:noreply, socket}
  end

  def handle_async(:load_track_search_results, {:ok, track_search_results}, socket) do
    {:noreply, assign(socket, :track_search_results, track_search_results)}
  end

  def handle_event("track_selected", %{"idx" => idx}, socket) do
    IO.inspect(socket.assigns.device_id)
    # SpotifyApi.set_device_id(user_token, device_id) |> IO.inspect()

    selected_track = socket.assigns.track_search_results
    |> Enum.at(String.to_integer(idx))

    bounds_form = %{"start_ms" => 0, "end_ms" => selected_track.duration_ms}
    |> to_form()

    snippet_search_form = %{"track" => "", "artist" => "", "album" => ""}
    |> to_form()

    socket = socket
    |> assign(:selected_track, selected_track)
    |> assign(:track_search_results, [])
    |> assign(:bounds_form, bounds_form)
    |> assign(:snippet_search_form, snippet_search_form)
    |> assign(:description, "")
    |> assign(:start_ms, 0)
    |> assign(:end_ms, selected_track.duration_ms)
    |> push_event("initialize_audio", %{
        "start_ms" => 0,
        "end_ms" => selected_track.duration_ms,
        "spotify_url" => selected_track.spotify_url
      })
    {:noreply, socket}
  end

  defp validate_bounds_no_overlap(changeset) do
    if !Enum.at(changeset.errors, 0) && get_field(changeset, :end_ms) - get_field(changeset, :start_ms) < 1000 do
      add_error(changeset, :_, "snippet must be at least one second long")
    else
      changeset
    end
  end

  defp validate_bounds(socket, form) do
    types = %{start_ms: :integer, end_ms: :integer}
    changeset = { %{}, types }
      |> cast(form, Map.keys(types))
      |> validate_number(
        :start_ms,
        greater_than_or_equal_to: 0,
        message: "Start must be greater than zero."
      )
      |> validate_number(
        :end_ms,
        less_than_or_equal_to: socket.assigns.selected_track.duration_ms,
        message: "End must be less than duration of song."
      )
      |> validate_bounds_no_overlap()

    if changeset.valid? do
      start_ms = get_field(changeset, :start_ms)
      end_ms = get_field(changeset, :end_ms)
      socket
        |> assign(:start_ms, start_ms)
        |> assign(:end_ms, end_ms)
        |> assign(:bounds_form, changeset)
        |> push_event("bounds_changed", %{"start_ms" => start_ms, "end_ms" => end_ms})
    else
      assign(socket, :bounds_form, changeset)
    end
  end

  def handle_event("validate_bounds", form, socket) do
    {:noreply, validate_bounds(socket, form)}
  end

  def handle_event("bound_markers_changed", bounds_ms, socket) do
    {:noreply, validate_bounds(socket, bounds_ms)}
  end

  def handle_event("track_marker_changed", ms, socket) do
    if !socket.assigns.device_connected? do
      {:noreply, assign(socket, :track_ms, ms)}
    else
      {:noreply, push_event(socket, "seek", %{ms: ms})}
    end
  end

  def handle_event("position_updated", ms, socket) do
    {:noreply, assign(socket, :track_ms, ms)}
  end

  def handle_event("toggle_play", _, socket) do
    %{
      device_connected?: device_connected?,
      player_url: player_url,
      selected_track: selected_track,
      playing?: playing?,
      user_token: user_token,
      device_id: device_id,
      track_ms: track_ms
    } = socket.assigns
    cond do
      device_connected? && player_url == selected_track.spotify_url ->
        {:noreply, push_event(socket, "toggle_play", %{})}
      !device_connected? && playing? ->
        Task.start(fn ->
          SpotifyApi.pause(user_token, device_id)
        end)
        {:noreply, socket}
      true ->
        Task.start(fn ->
          SpotifyApi.play_track_from_ms(user_token, device_id, selected_track.spotify_url, track_ms)
        end)
        {:noreply, socket}
      end
  end

  def handle_event("backward", _, socket) do
    {:noreply, push_event(socket, "backward", %{})}
  end

  def handle_event("description_changed", %{"description" => description}, socket) do
    {:noreply, assign(socket, :description, description)}
  end

  def handle_event("snippet_created", _, socket) do
    attrs = socket.assigns.selected_track
    |> Map.put(:start_ms, socket.assigns.start_ms)
    |> Map.put(:end_ms, socket.assigns.end_ms)
    |> Map.put(:description, socket.assigns.description)
    |> Map.put(:collection_id, socket.assigns.collection_to_associate.id)
    |> Map.put(:created_by_id, socket.assigns.user_id)

    socket = start_async(socket, :snippet_created, fn ->
      case Snippets.create_snippet(attrs) do
        {:ok, collection_snippet} -> collection_snippet
        other -> IO.inspect(other)
      end
    end)
    {:noreply, socket}
  end

  def handle_async(:snippet_created, {:ok, _}, socket) do
    socket = socket
      |> assign(:selected_track, nil)
      |> push_event("hide_modal", %{"id" => "add_snippet"})

    {:noreply, socket}
  end

  def handle_event("back", _, socket) do
    {:noreply, assign(socket, :selected_track, nil)}
  end

  def handle_event("width_computed", px, socket) do
    {:noreply, assign(socket, :track_width_px, px)}
  end

  defp get_first_error(form) do
    case Enum.at(form.errors, 0) do
      {_, { message, _ }} -> message
      _ -> nil
    end
  end

  def handle_event("track_removed", %{"spotify_url" => spotify_url}, socket) do
    if socket.assigns.player_url == spotify_url do
      socket = socket |> push_event("reset", %{})
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("collection_clicked", collection, _) do
    {:noreply, assign(:collection_to_associate, collection)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.modal
        id="add_snippet"
        on_cancel={JS.push("back", target: @myself)}
      >
        <div class="h-[75vh] flex flex-col gap-8 overflow-hidden">
          <div class="text-2xl font-bold"> Create Snippet </div>
          <div
            :if={!@selected_track}
            class="flex-1 flex flex-col gap-8 overflow-hidden"
            phx-mounted={JS.transition({"transition-opacity duration-150", "opacity-0", "opacity-100"})}
          >
            <.form
              for={@snippet_search_form}
              phx-change="search_form_change"
              phx-target={@myself}
            >
              <div class="flex gap-4 mb-4">
                <.input
                  class="flex-1"
                  label="Track"
                  field={@snippet_search_form["track"]}
                  phx-debounce="500"
                />
                <.input
                  class="flex-1"
                  label="Artist"
                  field={@snippet_search_form["artist"]}
                  phx-debounce="500"
                />
              </div>
              <div class="flex gap-4">
                <.input
                  class="flex-1"
                  label="Album"
                  field={@snippet_search_form["album"]}
                  phx-debounce="500"
                />
                <div class="flex-1" />
              </div>
            </.form>
            <ul class="flex-1 flex flex-col gap-2 overflow-scroll">
              <li
                :for={{track, i} <- Enum.with_index(@track_search_results)}
                class="flex items-center gap-2 hover:bg-zinc-100 pl-[5px] pr-[10px]"
                phx-value-idx={i}
                phx-click="track_selected"
                phx-target={@myself}
                id={"#{track.track}:#{i}"}
                phx-mounted={JS.transition({"transition-opacity duration-150", "opacity-0", "opacity-100"})}
              >
                <.track_display
                  track={track.track}
                  artist={track.artist}
                  album={track.album}
                  thumbnail_url={track.thumbnail_url}
                  spotify_url={track.spotify_url}
                  list_item?={true}
                />
              </li>
            </ul>
          </div>
          <div
            :if={@selected_track}
            id={@selected_track.track}
            class="flex-1 justify-around overflow-hidden flex flex-col gap-8"
            phx-mounted={JS.transition({"transition-opacity duration-150", "opacity-0", "opacity-100"})}
          >
            <div class="flex items-center gap-16">
              <div class="flex-1">
                <.track_display
                  track={@selected_track.track}
                  artist={@selected_track.artist}
                  album={@selected_track.album}
                  thumbnail_url={@selected_track.thumbnail_url}
                  spotify_url={@selected_track.spotify_url}
                />
              </div>
              <.form
                class="flex-1 flex flex-col"
                for={@bounds_form}
                as={:bounds}
                phx-change="validate_bounds"
                phx-target={@myself}
              >
                <div class="flex gap-2">
                  <.input
                    class="w-1/2 mt-1"
                    label="Start (ms)"
                    name="start_ms"
                    value={@start_ms}
                    phx-debounce="500"
                  />
                  <.input
                    class="w-1/2 mt-1"
                    label="End (ms)"
                    name="end_ms"
                    value={@end_ms}
                    phx-debounce="500"
                  />
                </div>
                <div
                  class="h-6 text-sm text-red-500"
                  phx-mounted={JS.transition({"transition-opacity duration-100", "opacity-0", "opacity-100"})}
                >
                  <%= get_first_error(@bounds_form) %>
                </div>
              </.form>
            </div>
            <div class="w-full flex justify-around items-center">
              <div class="flex gap-2">
                <button
                  class="cursor-pointer"
                  phx-click="backward"
                  phx-target={@myself}
                >
                  <.icon name="hero-backward" />
                </button>
                <button
                  class="cursor-pointer"
                  phx-click="toggle_play"
                  phx-target={@myself}
                >
                  <.icon name="hero-play" :if={!@playing?} />
                  <.icon name="hero-pause" :if={@playing?} />
                </button>
              </div>
              <div
                id="track"
                phx-hook="track"
                class="w-[80%] px-4 h-[4px] bg-zinc-400 relative"
              >
                <div
                  id="track-marker"
                  class="absolute left-[-4px] h-[8px] w-[8px] rounded-full translate-y-[-10px] cursor-pointer bg-zinc-800 z-20"
                  style={"transform:translateX(#{@track_ms * @track_width_px / @selected_track.duration_ms}px) translateY(-10px)"}
                />
                <div
                  class="bound-marker absolute left-[-2px] h-[24px] w-[4px] cursor-pointer bg-zinc-800"
                  style={"transform:translateX(#{@start_ms * @track_width_px / @selected_track.duration_ms}px) translateY(6px)"}
                />
                <div
                  class="bound-marker absolute left-[-2px] h-[24px] w-[4px] cursor-pointer bg-zinc-800"
                  style={"transform:translateX(#{@end_ms * @track_width_px / @selected_track.duration_ms}px) translateY(6px)"}
                />
                <div
                  id="background"
                  class="cursor-pointer h-[15px] absolute left-0 translate-y-[-15px] w-full"
                />
                <div
                  id="left-mask"
                  class="h-[15px] absolute left-0 origin-left w-full bg-white z-10"
                  style={"transform:translateY(-15px) scaleX(#{@start_ms / @selected_track.duration_ms})"}
                />
                <div
                  id="right-mask"
                  class="h-[15px] absolute right-0 origin-right w-full bg-white z-10"
                  style={"transform:translateY(-15px) scaleX(#{(@selected_track.duration_ms - @end_ms) / @selected_track.duration_ms})"}
                />
              </div>
            </div>
            <div class="flex-1 flex gap-16 overflow-hidden">
              <div class="flex-1">
                <.form
                  phx-change="description_changed"
                  phx-target={@myself}
                >
                  <.input
                    label="Description"
                    name="description"
                    value={@description}
                    type="textarea"
                    phx-debounce="250"
                  />
                </.form>
              </div>
              <div class="flex-1 overflow-hidden">
                <.live_component
                  module={AddToCollection}
                  id={:create}
                  user_id={@user_id}
                  collections={@collections}
                  selected_collection={@collection_to_associate}
                  collection_changed={fn collection ->
                    send_update(@myself, collection_to_associate: collection)
                  end}
                />
              </div>
            </div>
            <div class="flex justify-between">
              <button
                class="cursor-pointer w-8"
                phx-click="back"
                phx-target={@myself}
              >
                <.icon name="hero-arrow-uturn-left" />
              </button>
              <.button
                phx-click="snippet_created"
                phx-target={@myself}
                disabled={!@collection_to_associate}
                class="self-start"
              >
                Create snippet
              </.button>
            </div>
          </div>
        </div>
      </.modal>
    </div>

    """
  end
end
