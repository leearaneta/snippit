defmodule SnippitWeb.AddSnippet do
  use SnippitWeb, :live_component

  import SnippitWeb.CustomComponents, warn: false
  import Ecto.Changeset

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
      |> assign(:end_ms, nil)
      |> assign(:track_width_px, 0)
      |> assign(:description_form, to_form(%{"description" => ""}))
      |> assign(:collection_search_form, to_form(%{"search" => ""}))
      |> assign(:collection_search_results, [])

    {:ok, socket}
  end

  def handle_event("search_form_change", form, socket) do
    user_token = socket.assigns.user_token

    socket = start_async(socket, :load_track_search_results, fn ->
      SpotifyApi.search_tracks(user_token, form)
    end)
    {:noreply, socket}
  end

  def handle_async(:load_track_search_results, {:ok, track_search_results}, socket) do
    {:noreply, assign(socket, :track_search_results, track_search_results)}
  end

  def handle_event("selected_track", %{"idx" => idx}, socket) do
    selected_track = socket.assigns.track_search_results
      |> Enum.at(String.to_integer(idx))

    bounds_form = %{"start_ms" => 0, "end_ms" => selected_track.duration_ms}
      |> to_form()

    socket = socket
      |> assign(:selected_track, selected_track)
      |> assign(:track_search_results, [])
      |> assign(:bounds_form, bounds_form)
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
        message: "start must be greater than zero"
      )
      |> validate_number(
        :end_ms,
        less_than_or_equal_to: socket.assigns.selected_track.duration_ms,
        message: "end must be less than duration of song"
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
    {:noreply, push_event(socket, "seek", %{ms: ms})}
  end

  def handle_event("position_updated", ms, socket) do
    {:noreply, assign(socket, :track_ms, ms)}
  end

  def handle_event("toggle_play", _, socket) do
    if socket.assigns.player_url == socket.assigns.selected_track.spotify_url do
      {:noreply, push_event(socket, "toggle_play", %{})}
    else
      Task.start(fn ->
        SpotifyApi.play_track_from_ms(
          socket.assigns.user_token,
          socket.assigns.device_id,
          socket.assigns.selected_track.spotify_url,
          socket.assigns.start_ms
        )
      end)
      {:noreply, socket}
    end
  end

  def handle_event("backward", _, socket) do
    {:noreply, push_event(socket, "backward", %{})}
  end

  def handle_event("create_snippet", _, socket) do
    attrs = socket.assigns.selected_track
      |> Map.put(:start_ms, socket.assigns.start_ms)
      |> Map.put(:end_ms, socket.assigns.end_ms)
      |> Map.put(:description, Phoenix.HTML.Form.input_value(socket.assigns.description_form, :description))
      |> Map.put(:collection_id, socket.assigns.selected_collection.id)
      |> Map.put(:created_by_id, socket.assigns.current_user.id)

    socket = start_async(socket, :create_snippet, fn ->
      case Snippets.create_snippet(attrs) do
        {:ok, collection_snippet} -> collection_snippet
        other -> IO.inspect(other)
      end
    end)
    {:noreply, socket}
  end

  def handle_async(:create_snippet, {:ok, collection_snippet}, socket) do
    send(self(), {:snippet_created, collection_snippet })

    socket = socket
      |>  assign(:selected_track, nil)
      |>  push_event("hide_modal", %{"id" => "add_snippet"})

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
      socket = socket
        |> push_event("reset", %{})

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <.modal
        id="add_snippet"
        on_cancel={JS.push("back", target: @myself)}
      >
        <div class="h-[75vh] flex flex-col gap-8">
          <div class="text-2xl"> Create Snippet </div>
          <div
            :if={!@selected_track}
            class="flex-1 flex flex-col gap-8 overflow-hidden"
          >
            <.form
              for={@snippet_search_form}
              phx-change="search_form_change"
              phx-target={@myself}
            >
              <div class="flex gap-4 mb-4">
                <.input
                  class="flex-1"
                  label="track"
                  field={@snippet_search_form["track"]}
                  phx-debounce="500"
                />
                <.input
                  class="flex-1"
                  label="artist"
                  field={@snippet_search_form["artist"]}
                  phx-debounce="500"
                />
              </div>
              <div class="flex gap-4">
                <.input
                  class="flex-1"
                  label="album"
                  field={@snippet_search_form["album"]}
                  phx-debounce="500"
                />
                <div class="flex-1" />
              </div>
            </.form>
            <div class="flex-1 flex flex-col overflow-scroll">
              <ul :for={{track, i} <- Enum.with_index(@track_search_results)}>
                <li
                  class="flex items-center gap-2 cursor-pointer hover:bg-gray-100 h-[60px] pl-[5px]"
                  phx-value-idx={i}
                  phx-click="selected_track"
                  phx-target={@myself}
                >
                  <img src={track.thumbnail_url} width="50" height="50" />
                  <div class="flex flex-col">
                    <span class="font-bold"> <%= track.track %> </span>
                    <span> <%= track.artist %> </span>
                  </div>
                </li>
              </ul>
            </div>
          </div>
          <div
            :if={@selected_track}
            class="flex-1 justify-around flex flex-col gap-8"
          >
            <div class="flex items-center gap-16">
              <div class="flex-1 flex gap-2">
                <img src={@selected_track.thumbnail_url} width="50" height="50" />
                <div class="flex flex-col">
                  <span class="font-bold"> <%= @selected_track.track %> </span>
                  <span> <%= @selected_track.artist %> </span>
                </div>
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
                    label="start (ms)"
                    name="start_ms"
                    value={@start_ms}
                    phx-debounce="500"
                  />
                  <.input
                    class="w-1/2 mt-1"
                    label="end (ms)"
                    name="end_ms"
                    value={@end_ms}
                    phx-debounce="500"
                  />
                </div>
                <div class="h-6 text-sm text-red-500">
                  <%= get_first_error(@bounds_form) %>
                </div>
              </.form>
            </div>
            <div class="w-full flex justify-between items-center">
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
                class="w-[80%] px-4 h-[4px] bg-gray-400 relative"
              >
                <div
                  id="track-marker"
                  class="absolute left-[-2px] h-[6px] w-[4px] translate-y-[-10px] cursor-pointer bg-red-400"
                  style={"transform:translateX(#{@track_ms * @track_width_px / @selected_track.duration_ms}px) translateY(-10px)"}
                />
                <div
                  class="bound-marker absolute left-[-2px] h-[24px] w-[4px] cursor-pointer bg-orange-400"
                  style={"transform:translateX(#{@start_ms * @track_width_px / @selected_track.duration_ms}px)"}
                />
                <div
                  class="bound-marker absolute left-[-2px] h-[24px] w-[4px] cursor-pointer bg-orange-400"
                  style={"transform:translateX(#{@end_ms * @track_width_px / @selected_track.duration_ms}px)"}
                />
              </div>
            </div>
            <div class="flex gap-16">
              <div class="flex-1">
                <.form for={@description_form}>
                  <.input
                    label="description"
                    type="textarea"
                    field={@description_form["description"]}
                  />
                </.form>
              </div>
              <div class="flex-1 flex flex-col">
                <.form for={@collection_search_form}>
                  <.input
                    label="add to:"
                    type="hidden"
                    field={@collection_search_form["search"]}
                  />
                </.form>
                <div class="flex flex-col gap-4 justify-between">
                  <div class="flex flex-col">
                    <span class="font-bold"> <%= @selected_collection.name %> </span>
                    <span> <%= @selected_collection.description %> </span>
                  </div>
                  <.button
                    phx-click="create_snippet"
                    phx-target={@myself}
                    class="self-start"
                  >
                    create
                  </.button>
                </div>
              </div>
            </div>
            <button
              class="cursor-pointer w-8"
              phx-click="back"
              phx-target={@myself}
            >
              <.icon name="hero-arrow-uturn-left" />
            </button>
          </div>
        </div>
      </.modal>
    </div>

    """
  end
end