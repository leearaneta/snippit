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
    <.modal id="privacy_policy">
      <div class="h-[64vh] flex flex-col gap-8 overflow-scroll">
        <div class="text-2xl font-bold"> Privacy Policy </div>
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
            Continue to Snippit
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
    <div class="h-full px-4 py-10 sm:px-6 sm:py-28 lg:px-8 xl:px-28 xl:py-32 flex flex-col justify-between">
      <div class="flex flex-col gap-4 mx-auto max-w-xl lg:mx-0">
        <p class="text-base text-zinc-600">
          hey 👋 we're working on getting spotify's permission to deploy this app.
        </p>
        <p class="text-base text-zinc-600">
          if you're really eager to use it, you can email us at hello@snippit.studio and we'll allowlist your email!
        </p>
        <p class="text-base text-zinc-600">
          thank you for your patience 🙏
        </p>
      </div>
      <div class="flex flex-col gap-4 mx-auto max-w-xl lg:mx-0">
        <p class="text-[2rem] font-semibold leading-10 tracking-tighter text-zinc-900 text-balance">
          musical moodboarding (with friends)
        </p>
        <p class="text-base leading-7 text-zinc-600">
          create snippets of tracks and organize them to your heart's desire
        </p>
        <p class="text-sm leading-7 text-zinc-600">
          (requires spotify premium)
        </p>
        <button
          class={[
            "rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3 w-[10rem]",
            "text-sm font-semibold leading-6 text-white active:text-white/80",
            "flex items-center justify-around"
          ]}
          phx-click={show_modal("privacy_policy")}
        >
          <span> Login via </span>
          <div class="pt-[2px]">
            <svg alt="spotify" width="60" height="20" viewBox="180 120 440 125" fill="none" xmlns="http://www.w3.org/2000/svg">
              <rect width="430" height="132" transform="translate(185 112)"/>
              <path d="M289.032 170.52C268.001 157.925 233.314 156.765 213.237 162.908C212.468 163.14 211.66 163.218 210.86 163.138C210.061 163.058 209.285 162.82 208.578 162.439C207.871 162.058 207.246 161.542 206.74 160.919C206.234 160.296 205.856 159.58 205.629 158.811C205.154 157.255 205.315 155.575 206.076 154.137C206.837 152.699 208.137 151.619 209.692 151.133C232.736 144.076 271.05 145.44 295.262 159.933C298.162 161.671 299.115 165.444 297.395 168.364C296.992 169.058 296.455 169.665 295.815 170.149C295.175 170.634 294.444 170.987 293.666 171.188C292.888 171.388 292.078 171.433 291.282 171.318C290.487 171.203 289.722 170.932 289.032 170.52ZM288.343 189.176C287.998 189.749 287.543 190.247 287.003 190.643C286.463 191.038 285.85 191.323 285.199 191.48C284.549 191.637 283.873 191.663 283.212 191.558C282.55 191.452 281.917 191.216 281.348 190.865C263.817 179.991 237.08 176.845 216.335 183.198C215.693 183.391 215.019 183.456 214.352 183.388C213.685 183.321 213.038 183.122 212.449 182.804C211.859 182.486 211.338 182.055 210.916 181.536C210.494 181.016 210.179 180.418 209.99 179.777C209.598 178.48 209.734 177.081 210.368 175.884C211.003 174.686 212.085 173.787 213.38 173.38C237.074 166.126 266.535 169.64 286.673 182.125C289.06 183.61 289.815 186.767 288.343 189.176ZM280.361 207.09C280.087 207.549 279.724 207.949 279.293 208.267C278.862 208.584 278.373 208.813 277.852 208.94C277.332 209.067 276.792 209.09 276.263 209.006C275.733 208.922 275.226 208.735 274.771 208.454C259.445 199.01 240.167 196.876 217.454 202.112C216.931 202.23 216.39 202.244 215.862 202.153C215.334 202.062 214.829 201.867 214.376 201.58C213.924 201.294 213.533 200.92 213.225 200.482C212.918 200.044 212.701 199.549 212.586 199.027C212.341 197.971 212.526 196.861 213.099 195.94C213.673 195.02 214.588 194.364 215.646 194.115C240.498 188.384 261.816 190.854 279.016 201.452C279.938 202.027 280.596 202.94 280.848 203.995C281.099 205.051 280.924 206.162 280.361 207.09ZM250.443 112.187C214.405 112.187 185.198 141.645 185.198 177.984C185.198 214.328 214.405 243.78 250.443 243.78C286.475 243.78 315.687 214.328 315.687 177.984C315.687 141.645 286.475 112.187 250.437 112.187H250.443ZM362.7 172.929C351.438 170.218 349.431 168.32 349.431 164.322C349.431 160.549 352.959 158.008 358.196 158.008C363.274 158.008 368.312 159.938 373.594 163.909C373.754 164.03 373.952 164.074 374.15 164.047C374.248 164.031 374.341 163.997 374.424 163.945C374.507 163.893 374.579 163.825 374.636 163.744L380.137 155.923C380.246 155.768 380.292 155.578 380.267 155.39C380.241 155.203 380.146 155.032 380 154.911C373.715 149.824 366.636 147.354 358.362 147.354C346.2 147.354 337.705 154.713 337.705 165.246C337.705 176.543 345.037 180.536 357.7 183.627C368.478 186.129 370.297 188.23 370.297 191.981C370.297 196.134 366.62 198.719 360.699 198.719C354.122 198.719 348.758 196.486 342.76 191.244C342.687 191.179 342.601 191.129 342.508 191.098C342.415 191.067 342.317 191.055 342.219 191.062C342.121 191.07 342.026 191.097 341.939 191.143C341.852 191.188 341.775 191.251 341.713 191.327L335.544 198.73C335.419 198.877 335.356 199.068 335.369 199.261C335.383 199.454 335.471 199.635 335.616 199.764C342.601 206.05 351.184 209.367 360.446 209.367C373.555 209.367 382.023 202.145 382.023 190.969C382.023 181.52 376.427 176.295 362.7 172.929ZM421.191 185.59C421.191 193.565 416.318 199.137 409.339 199.137C402.448 199.137 397.244 193.318 397.244 185.59C397.244 177.868 402.442 172.049 409.344 172.049C416.208 172.049 421.191 177.742 421.191 185.59ZM411.676 161.72C405.998 161.72 401.334 163.981 397.492 168.606V163.403C397.493 163.207 397.417 163.018 397.28 162.878C397.142 162.738 396.955 162.658 396.759 162.655H386.67C386.572 162.656 386.476 162.676 386.386 162.714C386.296 162.752 386.214 162.807 386.145 162.876C386.077 162.946 386.023 163.028 385.986 163.118C385.949 163.209 385.931 163.306 385.931 163.403V221.23C385.931 221.643 386.262 221.978 386.67 221.978H396.759C396.955 221.975 397.142 221.895 397.28 221.755C397.417 221.615 397.493 221.426 397.492 221.23V202.976C401.34 207.326 405.998 209.449 411.676 209.449C422.233 209.449 432.917 201.254 432.917 185.59C432.917 169.921 422.233 161.72 411.676 161.72ZM460.31 199.219C453.077 199.219 447.631 193.362 447.631 185.59C447.631 177.791 452.89 172.126 460.145 172.126C467.422 172.126 472.907 177.989 472.907 185.766C472.907 193.56 467.615 199.219 460.31 199.219ZM460.31 161.726C446.716 161.726 436.065 172.286 436.065 185.761C436.065 199.093 446.644 209.543 460.145 209.543C473.784 209.543 484.467 199.021 484.467 185.59C484.467 172.209 473.861 161.72 460.31 161.72V161.726ZM513.498 162.655H502.401V151.215C502.402 151.117 502.384 151.02 502.348 150.93C502.311 150.839 502.257 150.756 502.188 150.687C502.12 150.617 502.038 150.562 501.947 150.524C501.857 150.486 501.76 150.467 501.662 150.467H491.574C491.378 150.47 491.192 150.549 491.054 150.688C490.917 150.827 490.84 151.014 490.84 151.21V162.655H485.989C485.892 162.656 485.795 162.676 485.705 162.714C485.616 162.752 485.534 162.807 485.466 162.877C485.398 162.946 485.344 163.029 485.308 163.119C485.272 163.209 485.254 163.306 485.256 163.403V172.148C485.256 172.555 485.587 172.891 485.989 172.891H490.84V195.512C490.84 204.653 495.35 209.29 504.247 209.29C507.864 209.29 510.863 208.536 513.696 206.914C513.81 206.849 513.905 206.755 513.971 206.642C514.036 206.529 514.071 206.401 514.071 206.27V197.943C514.071 197.816 514.038 197.692 513.977 197.581C513.915 197.471 513.826 197.378 513.719 197.311C513.612 197.244 513.49 197.206 513.365 197.201C513.239 197.195 513.114 197.221 513.002 197.278C511.056 198.268 509.181 198.719 507.081 198.719C503.845 198.719 502.395 197.234 502.395 193.917V172.885H513.498C513.596 172.884 513.692 172.864 513.782 172.826C513.872 172.788 513.954 172.733 514.023 172.664C514.091 172.594 514.145 172.512 514.182 172.422C514.219 172.331 514.237 172.235 514.237 172.137V163.392C514.237 163.295 514.219 163.198 514.182 163.108C514.145 163.018 514.091 162.936 514.022 162.867C513.954 162.798 513.872 162.744 513.782 162.706C513.692 162.669 513.595 162.65 513.498 162.65V162.655ZM552.17 162.699V161.297C552.17 157.161 553.742 155.313 557.27 155.313C559.37 155.313 561.063 155.736 562.953 156.374C563.065 156.409 563.183 156.418 563.298 156.399C563.413 156.38 563.522 156.334 563.615 156.264C563.711 156.195 563.789 156.104 563.843 155.999C563.896 155.894 563.924 155.777 563.924 155.659V147.09C563.925 146.931 563.875 146.775 563.78 146.646C563.686 146.517 563.553 146.422 563.4 146.375C560.686 145.542 557.86 145.133 555.021 145.165C545.704 145.165 540.775 150.456 540.775 160.455V162.611H535.93C535.733 162.612 535.545 162.691 535.407 162.83C535.269 162.97 535.191 163.158 535.191 163.354V172.143C535.191 172.555 535.522 172.891 535.93 172.891H540.781V207.783C540.781 208.195 541.106 208.525 541.514 208.525H551.603C552.005 208.525 552.336 208.195 552.336 207.783V172.885H561.757L576.184 207.766C574.547 211.435 572.932 212.166 570.738 212.166C568.957 212.166 567.088 211.627 565.17 210.571C565.081 210.523 564.984 210.494 564.883 210.484C564.783 210.475 564.681 210.486 564.585 210.516C564.489 210.55 564.401 210.603 564.326 210.672C564.251 210.741 564.191 210.825 564.15 210.918L560.732 218.48C560.652 218.65 560.641 218.844 560.699 219.023C560.757 219.202 560.881 219.351 561.046 219.443C564.323 221.318 568.046 222.279 571.824 222.226C579.266 222.226 583.384 218.728 587.017 209.312L604.515 163.711C604.559 163.598 604.575 163.476 604.561 163.355C604.548 163.234 604.505 163.119 604.438 163.018C604.371 162.919 604.281 162.837 604.175 162.78C604.069 162.724 603.951 162.694 603.831 162.694H593.329C593.175 162.694 593.025 162.743 592.899 162.832C592.774 162.922 592.679 163.048 592.629 163.194L581.874 194.181L570.093 163.172C570.041 163.031 569.947 162.91 569.824 162.825C569.7 162.739 569.554 162.693 569.404 162.694H552.17V162.699ZM529.75 162.655H519.661C519.465 162.658 519.278 162.738 519.14 162.878C519.003 163.018 518.927 163.207 518.928 163.403V207.783C518.928 208.195 519.259 208.525 519.667 208.525H529.755C530.158 208.525 530.489 208.195 530.489 207.783V163.398C530.489 163.202 530.411 163.014 530.272 162.874C530.134 162.735 529.946 162.656 529.75 162.655ZM524.755 142.448C522.827 142.46 520.983 143.234 519.626 144.602C518.27 145.969 517.514 147.817 517.522 149.741C517.517 150.694 517.701 151.639 518.061 152.522C518.423 153.405 518.954 154.208 519.626 154.886C520.299 155.564 521.098 156.103 521.979 156.472C522.86 156.842 523.805 157.034 524.761 157.04C526.69 157.028 528.535 156.253 529.891 154.884C531.248 153.515 532.004 151.666 531.994 149.741C531.994 145.71 528.752 142.448 524.761 142.448H524.755ZM613.539 167.072H611.692V169.448H613.539C614.46 169.448 615.011 168.991 615.011 168.26C615.011 167.484 614.46 167.072 613.539 167.072ZM614.735 170.46L616.748 173.298H615.05L613.247 170.696H611.692V173.298H610.276V165.779H613.594C615.325 165.779 616.466 166.676 616.466 168.177C616.491 168.699 616.331 169.213 616.014 169.63C615.698 170.047 615.246 170.341 614.735 170.46ZM613.164 163.282C609.526 163.282 606.775 166.197 606.775 169.767C606.775 173.331 609.509 176.207 613.126 176.207C616.764 176.207 619.521 173.292 619.521 169.723C619.521 166.159 616.781 163.282 613.164 163.282ZM613.126 176.922C612.188 176.92 611.26 176.733 610.395 176.371C609.53 176.01 608.746 175.482 608.086 174.817C607.427 174.152 606.906 173.363 606.553 172.496C606.2 171.63 606.023 170.702 606.031 169.767C606.031 165.84 609.173 162.567 613.164 162.567C614.102 162.569 615.03 162.756 615.895 163.118C616.76 163.479 617.544 164.007 618.204 164.672C618.863 165.337 619.384 166.126 619.737 166.993C620.09 167.859 620.267 168.787 620.259 169.723C620.259 173.65 617.117 176.928 613.126 176.928V176.922Z" fill="#1ED760"/>
            </svg>
          </div>
        </button>
      </div>
    </div>
    """
  end

end
