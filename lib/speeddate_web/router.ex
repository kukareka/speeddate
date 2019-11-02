defmodule SpeeddateWeb.Router do
  import Phoenix.LiveView.Router
  use SpeeddateWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SpeeddateWeb do
    pipe_through :browser

    live "/", ChatLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", SpeeddateWeb do
  #   pipe_through :api
  # end
end
