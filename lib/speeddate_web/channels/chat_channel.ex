defmodule SpeeddateWeb.ChatChannel do
  use Phoenix.Channel

  def join("chat:" <> _chat_id, _auth_msg, socket) do
    send(self(), :joined)
    {:ok, socket}
  end

  def handle_info(:joined, socket) do
    broadcast_from!(socket, "message", %{body: "{\"msg_type\": \"start\"}"})
    {:noreply, socket}
  end

  def handle_in("message", %{"body" => body}, socket) do
    broadcast_from!(socket, "message", %{body: body})
    {:noreply, socket}
  end
end