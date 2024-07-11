defmodule SnippitWeb.Router do
  use SnippitWeb, :router

  import SnippitWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SnippitWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SnippitWeb do
    pipe_through :browser

    live "/", HomeLive
    get "/hello", PageController, :hello
  end

  # Other scopes may use custom stacks.
  # scope "/api", SnippitWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:snippit, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SnippitWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", SnippitWeb do
    pipe_through :browser
    get "/auth/logout", AuthController, :logout

    pipe_through :redirect_if_user_is_authenticated
    get "/auth/login", AuthController, :login
    get "/auth/callback", AuthController, :callback
  end

end
