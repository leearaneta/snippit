defmodule SnippitWeb.CustomComponents do
  use SnippitWeb, :html

  attr :class, :string, default: nil
  slot :inner_block
  def collection_display(assigns) do
    ~H"""
      <div class={["flex h-12 justify-between", @class]}>
        <div class="flex flex-col">
          <span class="font-bold"> <%= @collection.name %> </span>
          <span> <%= @collection.description %> </span>
        </div>
        <div class="collection-buttons transition-opacity opacity-0 pointer-events-none">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    """
  end

  defp get_human_readable_time(ms) do
    secs = trunc(ms / 1000)
    remainder = rem(secs, 60)
    if remainder == secs do
      "#{remainder}s"
    else
      minutes = trunc((secs - remainder) / 60)
      "#{minutes}m #{remainder}s"
    end
  end

  slot :inner_block
  def snippet_display(assigns) do
    ~H"""
      <div class="snippet flex flex-col cursor-pointer w-52 h-60 border-2 rounded-2xl px-2 pt-2">
        <img
          class="rounded-2xl"
          src={@snippet.snippet.image_url}
        />
        <div class="flex justify-between items-center h-full">
          <div class="flex items-center gap-1">
            <%!-- <.icon name="hero-heart" class="cursor-pointer"/> --%>
            <div class="snippet-buttons transition-opacity opacity-0 pointer-events-none">
              <%= render_slot(@inner_block) %>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <span class="pb-1" :if={@loading?}>
              <.icon name="hero-arrow-path" class="animate-spin w-4 h-4" />
            </span>
            <span class="pb-1" :if={!@loading? && @playing?}>
              <.icon name="hero-speaker-wave" class="animate-pulse w-4 h-4" />
            </span>
            <span class="text-xs text-gray-500">
              <%= get_human_readable_time(@snippet.snippet.end_ms - @snippet.snippet.start_ms) %>
            </span>
          </div>
        </div>
      </div>
    """
  end

  attr :search, :string, required: true
  attr :el, :any, required: true
  attr :name, :string, required: true
  attr :items, :list, required: true
  attr :class, :string
  attr :rest, :global
  slot :inner_block
  slot :pinned_item
  def search(assigns) do
    ~H"""
      <div
        {@rest}
        class={["flex flex-col gap-2 h-full", @class]}
      >
        <.form
          phx-change={"#{@name}_search"}
          phx-target={@el}
        >
          <div class="w-full relative">
            <.icon
              name="hero-magnifying-glass top-1/2 translate-y-[-50%]"
              class="absolute left-[10px]"
            />
            <.input
              name="search"
              class="icon-input"
              value={@search}
              phx-debounce="250"
            />
            </div>
        </.form>
        <ul class="flex flex-col gap-2 overflow-scroll">
          <li :if={@pinned_item}>
            <%= render_slot(@pinned_item) %>
          </li>
          <li
            :for={{item, index} <- Enum.with_index(@items)}
            class="cursor-pointer"
            phx-click={
              JS.push(
                "#{@name}_clicked",
                value: %{"index" => index, "id" => item.id}
              )
            }
            phx-target={@el}
          >
            <%= render_slot(@inner_block, %{"item" => item, "index" => index}) %>
          </li>
        </ul>
      </div>
    """
  end

end
