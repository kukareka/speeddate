defmodule SpeeddateWeb.PageController do
  use SpeeddateWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
