defmodule SnippitWeb.HelloLive do
  use SnippitWeb, :live_view

  def mount(_, _, socket) do
    {:ok, assign(socket, :privacy_policy_accepted?, false)}
  end

  def handle_event("accept_privacy_policy_changed", %{"privacy_policy_accepted?" => privacy_policy_accepted?}, socket) do
    {:noreply, assign(socket, :privacy_policy_accepted?, privacy_policy_accepted?)}
  end

  def handle_event("login_clicked", _, socket) do
    {:noreply, redirect(socket, to: ~p"/auth/login") }
  end

  def render(assigns) do
    ~H"""
    <.flash_group flash={@flash} />
    <.modal id="privacy_policy">
      <div class="h-[64vh] flex flex-col gap-8 overflow-scroll">
        <div class="text-2xl"> Privacy Policy </div>
        <div class="flex flex-col gap-8">
          <span> A couple of things to know before we get started... </span>
          <ul class="flex flex-col gap-4 ml-8 list-disc">
            <li>
              We store your email so we can notify you when someone has shared a collection with you.
            </li>
            <li>
              We store your username to display to others, and your Spotify ID so we can find you in our database.
            </li>
            <li>
              We transfer your Spotify playback to the device running Snippit when necessary. This is limited to:
              <ul class="ml-8 mt-2 list-disc flex flex-col gap-2">
                <li> when a snippet is clicked </li>
                <li> when creating a snippet </li>
              </ul>
            </li>
          </ul>
        </div>
        <.form
          class="flex flex-col gap-8"
          phx-change="accept_privacy_policy_changed"
          phx-submit="login_clicked"
        >
          <.input
            label="I accept Snippit's privacy policy"
            name="privacy_policy_accepted?"
            type="checkbox"
          />
          <.button
            class="w-40"
            disabled={!@privacy_policy_accepted?}
          >
            continue to snippit
          </.button>
        </.form>
      </div>
    </.modal>
    <div class="h-full left-[40rem] fixed inset-y-0 right-0 z-0 hidden lg:block xl:left-[50rem]">
      <svg
        viewBox="0 0 1480 957"
        fill="none"
        aria-hidden="true"
        class="absolute inset-0 h-full w-full"
        preserveAspectRatio="xMinYMid slice"
      >
        <path fill="#EE7868" d="M0 0h1480v957H0z" />
        <path
          d="M137.542 466.27c-582.851-48.41-988.806-82.127-1608.412 658.2l67.39 810 3083.15-256.51L1535.94-49.622l-98.36 8.183C1269.29 281.468 734.115 515.799 146.47 467.012l-8.928-.742Z"
          fill="#FF9F92"
        />
        <path
          d="M371.028 528.664C-169.369 304.988-545.754 149.198-1361.45 665.565l-182.58 792.025 3014.73 694.98 389.42-1689.25-96.18-22.171C1505.28 697.438 924.153 757.586 379.305 532.09l-8.277-3.426Z"
          fill="#FA8372"
        />
        <path
          d="M359.326 571.714C-104.765 215.795-428.003-32.102-1349.55 255.554l-282.3 1224.596 3047.04 722.01 312.24-1354.467C1411.25 1028.3 834.355 935.995 366.435 577.166l-7.109-5.452Z"
          fill="#E96856"
          fill-opacity=".6"
        />
        <path
          d="M1593.87 1236.88c-352.15 92.63-885.498-145.85-1244.602-613.557l-5.455-7.105C-12.347 152.31-260.41-170.8-1225-131.458l-368.63 1599.048 3057.19 704.76 130.31-935.47Z"
          fill="#C42652"
          fill-opacity=".2"
        />
        <path
          d="M1411.91 1526.93c-363.79 15.71-834.312-330.6-1085.883-863.909l-3.822-8.102C72.704 125.95-101.074-242.476-1052.01-408.907l-699.85 1484.267 2837.75 1338.01 326.02-886.44Z"
          fill="#A41C42"
          fill-opacity=".2"
        />
        <path
          d="M1116.26 1863.69c-355.457-78.98-720.318-535.27-825.287-1115.521l-1.594-8.816C185.286 163.833 112.786-237.016-762.678-643.898L-1822.83 608.665 571.922 2635.55l544.338-771.86Z"
          fill="#A41C42"
          fill-opacity=".2"
        />
      </svg>
    </div>
    <div class="px-4 py-10 sm:px-6 sm:py-28 lg:px-8 xl:px-28 xl:pt-[24rem] xl:pb-32">
      <div class="mx-auto max-w-xl lg:mx-0">
        <p class="text-[2rem] mt-4 font-semibold leading-10 tracking-tighter text-zinc-900 text-balance">
          musical moodboarding (with friends)
        </p>
        <p class="mt-4 mb-2 text-base leading-7 text-zinc-600">
          create snippets of tracks and organize them to your heart's desire
        </p>
        <p class="mt-2 mb-8 text-sm leading-7 text-zinc-600">
          (requires spotify premium)
        </p>
        <button
          class={[
            "rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
            "text-sm font-semibold leading-6 text-white active:text-white/80"
          ]}
          phx-click={show_modal("privacy_policy")}
        >
          login via spotify
        </button>
      </div>
    </div>
    """
  end

end