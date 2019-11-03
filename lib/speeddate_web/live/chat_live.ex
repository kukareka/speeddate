defmodule SpeeddateWeb.ChatLive do
  use Phoenix.LiveView

  @genders %{"male" => :male, "female" => :female}

  def mount(%{}, socket) do
    {:ok, assign(socket, state: :sign_in, blacklist: [])}
  end

  def try_match(socket) do
    case Speeddate.Matcher.match(self(), socket.assigns[:gender], socket.assigns[:blacklist]) do
      {:match, opponent_view} ->
        chat_topic = Ecto.UUID.generate
        send(
          opponent_view,
          %{
            message: "connect_offer",
            opponent_view: self(),
            opponent_name: socket.assigns[:name],
            chat_topic: chat_topic
          }
        )
        assign(
          socket,
          state: :wait,
          opponent_view: opponent_view,
          chat_topic: chat_topic
        )
      {:no_match} -> assign(socket, state: :wait)
    end
  end

  def rematch(socket) do
    IO.puts("rematch: #{socket.assigns[:name]}")

    opponent_view = socket.assigns[:opponent_view]

    socket = assign(
      socket,
      blacklist: [opponent_view | socket.assigns[:blacklist]],
      opponent_view: nil,
      opponent_socket: nil
    )

    try_match(socket)
  end

  defp disconnect(socket) do
    IO.puts("disconnect: #{socket.assigns[:name]}")

    case socket.assigns.state do
      :wait -> Speeddate.Matcher.disconnect(self(), socket.assigns[:gender])
      :chat -> send(socket.assigns[:opponent_view], %{message: "peer_disconnected"})
      no_match -> no_match
    end
  end

  def handle_event("sign_in", %{"name" => name, "gender" => gender}, socket) do
    IO.puts("sign_in: #{name}")
    socket = assign(socket, name: name, gender: @genders[gender])
    socket = try_match(socket)

    {:noreply, socket}
  end

  def handle_event("rematch", %{}, socket) do
    opponent_view = socket.assigns[:opponent_view]

    socket = rematch(socket)
    send(opponent_view, %{message: "rematch"})

    {:noreply, socket}
  end

  def handle_event("disconnect", %{}, socket) do
    disconnect(socket)

    {:noreply, assign(socket, state: :sign_in)}
  end

  def handle_info(%{message: "connect_offer", opponent_view: opponent_view, opponent_name: opponent_name, chat_topic: chat_topic}, socket) do
    IO.puts("connect_offer: #{socket.assigns[:name]} => #{opponent_name}")

    send(opponent_view, %{message: "connect_answer", opponent_name: socket.assigns[:name]})
    {:noreply, assign(socket, state: :chat, opponent_name: opponent_name, opponent_view: opponent_view, chat_topic: chat_topic)}
  end

  def handle_info(%{message: "connect_answer", opponent_name: opponent_name}, socket) do
    IO.puts("connect_answer: #{socket.assigns[:name]} => #{opponent_name}")
    {:noreply, assign(socket, state: :chat, opponent_name: opponent_name)}
  end

  def handle_info(%{message: "rematch"}, socket) do
    socket = rematch(socket)
    {:noreply, socket}
  end

  def handle_info(%{message: "peer_disconnected"}, socket) do
    IO.puts("peer_disconnected: #{socket.assigns[:name]}")
    {:noreply, try_match(socket)}
  end

  def render(assigns) do
    Phoenix.View.render(SpeeddateWeb.PageView, "index.html", assigns)
  end

  def terminate(_reason, socket) do
    disconnect(socket)
  end
end
