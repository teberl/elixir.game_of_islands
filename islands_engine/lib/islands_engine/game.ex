defmodule IslandsEngine.Game do
  @moduledoc """
  The Game module implements a GenServer which contains all the data
  and game logic for islands.
  Each instance of this GenServer is started as a separate process and
  represents an individual game.
  """
  use GenServer
  alias IslandsEngine.{Board, Guesses, Rules}

  # TODO create defstruct for game_state
  # TODO create struct for player
  # TODO Use structs and add @spec and @type and @typedoc

  # -----------------------------------------------------
  # START INIT NEW GAME
  # -----------------------------------------------------

  @spec start_link(binary()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(name) when is_binary(name) do
    GenServer.start_link(__MODULE__, name, [])
  end

  @typedoc """
  Map containing the player name, a map of the board and
  a map with guesses, collecting hits and misses
  """
  @type player() :: %{name: any(), board: map(), guesses: Guesses.t()}

  @spec init(any()) ::
          {:ok,
           %{
             player1: player(),
             player2: player(),
             rules: Rules.t()
           }}
  def init(name) do
    player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    {:ok, %{player1: player1, player2: player2, rules: %Rules{}}}
  end

  # -----------------------------------------------------
  # END INIT NEW GAME
  # -----------------------------------------------------

  # -----------------------------------------------------
  # START ADD PLAYER
  # -----------------------------------------------------

  @doc """
  Add the second player to the game, name must be a binary string.

  Triggers the :add_player action in the state_machine,
  afterwards the game_state becomes :player_set
  """
  def add_player(game, name) when is_binary(name) do
    GenServer.call(game, {:add_player, name})
  end

  @doc false
  def handle_call({:add_player, name}, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, :add_player) do
      state
      |> update_player2_name(name)
      |> update_rules(rules)
      |> reply_sucess(:ok)
    else
      :error -> {:reply, :error, state}
    end
  end

  @doc false
  defp update_player2_name(state, name) do
    put_in(state.player2.name, name)
  end

  @doc false
  defp update_rules(state, rules), do: Map.put(state, :rules, rules)
  @doc false
  defp reply_sucess(state, reply), do: {:reply, reply, state}

  # -----------------------------------------------------
  # END ADD PLAYER
  # -----------------------------------------------------

  # -----------------------------------------------------
  # START POSITION ISLANDS
  # -----------------------------------------------------

  # -----------------------------------------------------
  # END POSITION ISLANDS
  # -----------------------------------------------------
end
