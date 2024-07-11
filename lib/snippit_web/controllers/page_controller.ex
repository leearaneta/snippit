defmodule SnippitWeb.PageController do
  use SnippitWeb, :controller

  def hello(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :hello, layout: false)
  end
end
