defmodule PokerWeb.PubSub do
  def subscribe(topic) do
    Phoenix.PubSub.subscribe(Poker.PubSub, topic)
  end

  def broadcast(message, event) do
    Phoenix.PubSub.broadcast(Poker.PubSub, "#{message.room_id}", {event, message})
    {:ok, message}
  end
end
