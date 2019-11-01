defmodule Speeddate.Repo do
  use Ecto.Repo,
    otp_app: :speeddate,
    adapter: Ecto.Adapters.Postgres
end
