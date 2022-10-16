defmodule Poker.RoomAgent do
  require Logger
  use Agent

  @number_sets %{
    fibonnaci: [1, 2, 3, 5, 8, 13],
    sequential: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    tshirt: ["XS", "S", "M", "L", "XL"]
  }

  def start_link(_) do
    Agent.start_link(fn -> Map.new() end, name: __MODULE__)
  end

  def get_room(id) do
    Agent.get(__MODULE__, &Map.fetch(&1, id))
  end

  def get_number_sets(), do: @number_sets

  def create_room() do
    new_id = generate_id()
    Agent.update(__MODULE__, &Map.put(&1, new_id, Poker.Room.new(@number_sets[:fibonnaci])))
    Logger.debug("New room created with id #{new_id}")

    {:ok, new_id}
  end

  def join_room(id, socket_id) do
    Logger.debug("User #{socket_id} joins room #{id}")

    Agent.update(__MODULE__, fn room_map ->
      update_in(room_map, [id, Access.key(:voter_count)], fn current_count ->
        current_count + 1
      end)
    end)

    Agent.get(__MODULE__, &Map.fetch(&1, id))
  end

  def leave_room(id, socket_id, is_voting) do
    Logger.debug("User #{socket_id} leaving room #{id}")

    if is_voting do
      Agent.update(__MODULE__, fn room_map ->
        result =
          update_in(room_map, [id, Access.key(:voter_count)], fn current_count ->
            current_count - 1
          end)

        {_popped, result} = pop_in(result, [id, Access.key(:votes), socket_id])

        if result[id].voter_count == 0 do
          {_popped, result} = pop_in(room_map, [id])
          result
        else
          result
        end
      end)
    end

    case Agent.get(__MODULE__, &Map.fetch(&1, id)) do
      :error ->
        {:ok, nil}

      res ->
        res
    end
  end

  def vote(id, socket_id, vote) do
    Agent.update(__MODULE__, fn room_map ->
      update_in(room_map, [id, Access.key(:votes), socket_id], fn _ ->
        vote
      end)
    end)

    Agent.get(__MODULE__, &Map.fetch(&1, id))
  end

  def reset_votes(id) do
    Logger.debug("Resetting votes for room #{id}")

    Agent.update(__MODULE__, fn room_map ->
      update_in(room_map, [id, Access.key(:votes)], fn _ ->
        Map.new()
      end)
    end)

    Agent.get(__MODULE__, &Map.fetch(&1, id))
  end

  def toggle_voting(id, socket_id, is_voting) do
    Logger.debug("Toggling voter for user #{socket_id}, status to #{!is_voting}")

    val = if is_voting, do: -1, else: 1

    Agent.update(__MODULE__, fn room_map ->
      result =
        update_in(room_map, [id, Access.key(:voter_count)], fn current_count ->
          current_count + val
        end)

      {_popped, result} = pop_in(result, [id, Access.key(:votes), socket_id])
      result
    end)

    {!is_voting, Agent.get(__MODULE__, &Map.fetch(&1, id))}
  end

  def change_set(id, set) do
    Logger.debug("Changing set for room #{id} to #{set}")

    Agent.update(__MODULE__, fn room_map ->
      update_in(room_map, [id, Access.key(:number_set)], fn _ ->
        @number_sets[String.to_existing_atom(set)]
      end)
    end)

    Agent.get(__MODULE__, &Map.fetch(&1, id))
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.url_encode64() |> binary_part(0, 8)
  end
end
