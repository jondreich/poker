defmodule PokerWeb.IndexLive do
  use PokerWeb, :live_view

  import Poker.RoomAgent

  @impl true
  def render(assigns) do
    ~H"""
    <form phx-submit="new_room">
    <button type="submit" class="hover-text hover-panel p-8 inline-flex items-center">
        <svg class="fill-current w-4 h-4 mr-2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 0c-6.627 0-12 5.373-12 12s5.373 12 12 12 12-5.373 12-12-5.373-12-12-12zm7 14h-5v5h-4v-5h-5v-4h5v-5h4v5h5v4z"/></svg>
        <span>New Room</span>
      </button>
    </form>
    """
  end

  @impl true
  def handle_event("new_room", _, socket) do
    {:ok, id} = create_room()
    {:noreply, redirect(socket, to: "/room/#{id}")}
  end
end
