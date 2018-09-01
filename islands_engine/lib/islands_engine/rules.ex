defmodule IslandsEngine.Rules do
  alias __MODULE__

  @type game_state :: :initialized | :players_set | :player1_turn | :player2_turn | :game_over

  @typedoc """
  The state value for a player, if both players have :islands_set
  the game_state can change to :player1_turn and guessing can start
  """
  @type player_state :: :islands_not_set | :islands_set

  @typedoc """
  Action types which can be performed an the state_machine
  """
  @type actions ::
          :add_player
          | {:position_island, :player1 | :player2}
          | {:set_islands, :player1 | :player2}
          | {:guess_coordinate, :player1 | :player2}
          | {:win_check, :win | :no_win}

  @typedoc """
  IslandsEngine.Rules.t() represents the state_machine
  """
  @type t :: %__MODULE__{state: game_state(), player1: player_state(), player2: player_state()}
  defstruct(
    state: :initialized,
    player1: :islands_not_set,
    player2: :islands_not_set
  )

  @spec new() :: IslandsEngine.Rules.t()
  def new(), do: %Rules{}

  @spec check(IslandsEngine.Rules.t(), IslandsEngine.Rules.actions()) ::
          :error
          | {:ok, IslandsEngine.Rules.t()}
  def check(%Rules{state: :initialized} = rules, :add_player) do
    {:ok, %Rules{rules | state: :players_set}}
  end

  def check(%Rules{state: :players_set} = rules, {:position_island, player}) do
    case Map.fetch!(rules, player) do
      :islands_set -> :error
      :islands_not_set -> {:ok, rules}
    end
  end

  def check(%Rules{state: :players_set} = rules, {:set_islands, player}) do
    rules = Map.put(rules, player, :islands_set)

    case both_players_islands_set?(rules) do
      true -> {:ok, %Rules{rules | state: :player1_turn}}
      false -> {:ok, rules}
    end
  end

  def check(%Rules{state: :player1_turn} = rules, {:guess_coordinate, :player1}) do
    {:ok, %Rules{rules | state: :player2_turn}}
  end

  def check(%Rules{state: :player1_turn} = rules, {:win_check, win_or_not}) do
    case win_or_not do
      :no_win -> {:ok, rules}
      :win -> {:ok, %Rules{rules | state: :game_over}}
    end
  end

  def check(%Rules{state: :player2_turn} = rules, {:guess_coordinate, :player2}) do
    {:ok, %Rules{rules | state: :player1_turn}}
  end

  def check(%Rules{state: :player2_turn} = rules, {:win_check, win_or_not}) do
    case win_or_not do
      :no_win -> {:ok, rules}
      :win -> {:ok, %Rules{rules | state: :game_over}}
    end
  end

  def check(_state, _action), do: :error

  defp both_players_islands_set?(rules) do
    rules.player1 == :islands_set && rules.player2 == :islands_set
  end
end
