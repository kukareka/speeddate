defmodule Speeddate.Matcher do
  use Agent

  @opponent_genders %{:male => :female, :female => :male}

  def start_link(_) do
    Agent.start_link(fn -> %{male: [], female: []} end, name: __MODULE__)
  end
#
#  def put(gender, socket) do
#    Agent.update(__MODULE__, fn queue -> %{queue | gender => [socket | queue[gender]]} end)
#  end

  def match(view, gender, blacklist) do
    opponent_gender = @opponent_genders[gender]
    Agent.get_and_update(__MODULE__, fn queue ->
      opponent_queue = queue[opponent_gender]
      case find_match(blacklist, opponent_queue) do
        {:no_match} ->
          {{:no_match}, %{queue | gender => [view | queue[gender]]}}
        {:match, opponent_view, new_opponent_queue} ->
          {{:match, opponent_view}, %{queue | opponent_gender => new_opponent_queue}}
      end
    end)
  end

  defp find_match(_blacklist, []) do
    {:no_match}
  end

  defp find_match(blacklist, [opponent_candidate | opponent_queue_tail]) do
    if opponent_candidate in blacklist do
      case find_match(blacklist, opponent_queue_tail) do
        {:match, matched_opponent, new_opponent_queue} ->
          {:match, matched_opponent, [opponent_candidate | new_opponent_queue]}
        no_match -> no_match
      end
    else
      {:match, opponent_candidate, opponent_queue_tail}
    end
  end
end