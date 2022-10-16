defmodule PokerWeb.RoomLive do
  use PokerWeb, :live_view
  alias Poker.RoomAgent
  import PokerWeb.PubSub

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @loading do %>
      Loading...
    <% else %>
    <div class="flex flex-col">
        <div class="grid gap-4 md:grid-cols-6 sm:grid-cols-3">
        <%= if map_size(@room.votes) == @room.voter_count do %>
          <%= for {_k, v} <- @room.votes do %>
            <%= vote_card(assigns, v) %>
          <% end %>
        <% else %>
          <%= for _ <- 1..@room.voter_count do %>
            <%= hidden_card(assigns) %>
          <% end %>
        <% end %>
      </div>
      <br/>
      <div class="grid gap-4 md:grid-cols-6 sm:grid-cols-3">
        <%= for value <- @room.number_set do %>
          <%= vote_button(assigns, value) %>
        <% end %>
      </div>
      <br/>
      <div class="flex inline-flex justify-between">
        <select phx-click="change_set" class="">
          <%= for {k, _v} <- Poker.RoomAgent.get_number_sets() do %>
            <option>
              <%= k %>
            </option>
          <% end %>
        </select>
        <button phx-click="toggle_voting" name="toggle_voting" class="bg-blue-700 border border-1 border-blue-500 text-gray-200 font-bold p-2 inline-flex items-center hover:bg-blue-600">
          <%= if @is_voting do %>
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6 mr-1">
              <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
            </svg>
            Voting
          <% else %>
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6 mr-1">
              <path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            Observing
          <% end %>
        </button>

        <button phx-click="reset" name="reset" class="bg-red-700 border border-1 border-red-500 text-gray-200 font-bold p-2 inline-flex items-center hover:bg-red-600">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6 mr-2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182m0-4.991v4.99" />
          </svg>
          Reset
        </button>
      </div>
    </div>
    <% end %>
    """
  end

  def hidden_card(assigns) do
    ~H"""
    <div class="flex bg-neutral-100 text-slate-900 drop-shadow-md font-bold h-36 rounded justify-center items-center outline outline-double outline-slate-800 outline-offset-[-8px]">
        <div class="flex flex-col flex-1 h-full rounded outline outline-[8px] outline-slate-200 outline-offset-[-8px] stripes" />
    </div>
    """
  end

  @spec vote_card(any, any) :: Phoenix.LiveView.Rendered.t()
  def vote_card(assigns, vote) do
    ~H"""
    <div class="flex bg-neutral-100 text-slate-900 drop-shadow-md font-bold h-36 rounded justify-center items-center outline outline-double outline-slate-800 outline-offset-[-8px]">
      <div class="flex flex-col flex-1 h-full px-3 py-2 text-sm justify-between">
        <span class="flex justify-start">
          <%= vote %>
        </span>
        <span class="flex justify-center text-2xl">
          <%= vote %>
        </span>
        <span class="flex justify-end">
          <%= vote %>
        </span>
      </div>
    </div>
    """
  end

  def vote_button(assigns, value) do
    disabled = !assigns.is_voting || map_size(assigns.room.votes) == assigns.room.voter_count

    ~H"""
    <button phx-click="vote" name="value" disabled={ disabled } value={ value } class="hover-panel hover-text h-24 w-24">
      <%= if "#{value}" == @current_vote do %>
        <span class="text-blue-500">
          <%= value %>
        </span>
      <% else %>
        <%= value %>
      <% end %>
    </button>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case connected?(socket) do
      true ->
        case RoomAgent.get_room(id) do
          :error ->
            {:ok, redirect(socket, to: "/")}

          {:ok, room} ->
            subscribe(id)
            join_room(id, socket.id)

            {:ok,
             assign(
               socket,
               room_id: id,
               room: room,
               loading: false,
               current_vote: nil,
               is_voting: true
             )}
        end

      false ->
        {:ok, assign(socket, loading: true)}
    end
  end

  @impl true
  def handle_event("vote", %{"value" => value}, socket) do
    vote(socket.assigns.room_id, socket.id, value)
    {:noreply, assign(socket, current_vote: "#{value}")}
  end

  @impl true
  def handle_event("reset", _, socket) do
    reset_votes(socket.assigns.room_id)
    {:noreply, assign(socket, current_vote: nil)}
  end

  @impl true
  def handle_event("toggle_voting", _, socket) do
    is_voting = toggle_voting(socket.assigns.room_id, socket.id, socket.assigns.is_voting)
    {:noreply, assign(socket, is_voting: is_voting)}
  end

  @impl true
  def handle_event("change_set", %{"value" => set_name}, socket) do
    change_set(socket.assigns.room_id, set_name)
    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    if socket.assigns.room_id,
      do: leave_room(socket.assigns.room_id, socket.id, socket.assigns.is_voting)
  end

  @impl true
  def handle_info({:update, %{room: room}}, socket) do
    {:noreply,
     assign(
       socket,
       room: room
     )}
  end

  @impl true
  def handle_info({:reset, %{room: room}}, socket) do
    {:noreply,
     assign(
       socket,
       room: room,
       current_vote: nil
     )}
  end

  defp join_room(room_id, socket_id) do
    {:ok, updated_room} = RoomAgent.join_room(room_id, socket_id)
    broadcast(%{room_id: room_id, room: updated_room}, :update)
  end

  defp leave_room(room_id, socket_id, is_voting) do
    {:ok, updated_room} = RoomAgent.leave_room(room_id, socket_id, is_voting)
    broadcast(%{room_id: room_id, room: updated_room}, :update)
  end

  defp vote(room_id, socket_id, vote) do
    {:ok, updated_room} = RoomAgent.vote(room_id, socket_id, vote)
    broadcast(%{room_id: room_id, room: updated_room}, :update)
  end

  defp reset_votes(room_id) do
    {:ok, updated_room} = RoomAgent.reset_votes(room_id)
    broadcast(%{room_id: room_id, room: updated_room}, :reset)
  end

  defp toggle_voting(room_id, socket_id, is_voting) do
    {is_voting, {:ok, updated_room}} = RoomAgent.toggle_voting(room_id, socket_id, is_voting)
    broadcast(%{room_id: room_id, room: updated_room}, :update)
    is_voting
  end

  defp change_set(room_id, set_name) do
    {:ok, updated_room} = RoomAgent.change_set(room_id, set_name)
    broadcast(%{room_id: room_id, room: updated_room}, :update)
  end
end
