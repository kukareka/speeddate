# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :speeddate, SpeeddateWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "tyUdMti9KF6FhrPf4h6mJ4gc+DAqSsyEK0b1nmqE3o7NHqxVd/9jVbch6Xp2tWJe",
  render_errors: [view: SpeeddateWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Speeddate.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "VJ31dVFSQeni63fsdjY6roWQ9iKSDdyA"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
