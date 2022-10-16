defmodule Poker.Room do
  defstruct [
    :voter_count,
    :votes,
    :number_set
  ]

  def new(number_set) do
    %Poker.Room{
      voter_count: 0,
      votes: Map.new(),
      number_set: number_set
    }
  end
end
