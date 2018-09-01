defmodule IslandsEngine.Game do
  @moduledoc """
  The Game module implements a GenServer which contains all the data
  and game logic for islands.
  Each instance of this GenServer is started as a separate process and
  represents an individual game.
  """
  use GenServer
  alias IslandsEngine.{Board, Coordinate, Guesses, Rules, Island}

  @typedoc """
  t:IslandsEngine.Game.player/0

  Stores players name, his boards with set islands and the players
  guesses with hits and misses
  """
  @type player() :: %{name: any(), board: map(), guesses: Guesses.t()}

  @players [:player1, :player2]

  @doc """
  Starts a new instance of islands game instance

  ##Examples

    iex> IslandsEngine.Game.start_link("tina")
    {:ok, #PID<0.232.0>}
  """
  @spec start_link(binary()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(name) when is_binary(name) do
    GenServer.start_link(__MODULE__, name, [])
  end

  @doc """
  Adds the second player to the game.

  Triggers the :add_player action in the state_machine,
  afterwards the game_state becomes :player_set

  ## Examples

    iex> IslandsEngine.Game.add_player(pid, "tom")
    :ok
  """
  @spec add_player(pid(), binary()) :: :ignore | {:error, any()} | :ok
  def add_player(pid, name) when is_binary(name) do
    GenServer.call(pid, {:add_player, name})
  end

  @doc """
  Position a island type on the board

  ## Examples

    iex> IslandsEngine.Game.position_island(pid, :player1, :dot, 1, 1)
    :ok
  """
  @spec position_island(
          pid(),
          :player1 | :player2,
          Island.island_type(),
          1..10,
          1..10
        ) :: any()
  def position_island(pid, player, island_type, row, col) when player in @players do
    GenServer.call(pid, {:position_island, player, island_type, row, col})
  end

  @doc """
  Once a player finished positioning their islands on the board, they will be marked as set.

  ## Examples

    iex> IslandsEngine.Game.set_islands(pid, :player1)
    :ok
  """
  @spec set_islands(pid(), :player1 | :player2) :: any()
  def set_islands(pid, player) when player in @players do
    GenServer.call(pid, {:set_islands, player})
  end

  @spec guess_coordinate(
          pid(),
          :player1 | :player2,
          1..10,
          1..10
        ) :: any()
  def guess_coordinate(pid, player, row, col) when player in @players do
    GenServer.call(pid, {:guess_coordinate, player, row, col})
  end

  # -----------------------------------
  # ------- GenServer callbacks -------
  # -----------------------------------
  @spec init(name :: any()) :: {:ok, %{player1: player(), player2: player(), rules: %Rules{}}}
  def init(name) do
    player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    {:ok, %{player1: player1, player2: player2, rules: %Rules{}}}
  end

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

  def handle_call({:position_island, player, island_type, row, col}, _from, state) do
    board = player_board(state, player)

    with {:ok, rules} <- Rules.check(state.rules, {:position_island, player}),
         {:ok, coordinate} <- Coordinate.new(row, col),
         {:ok, island} <- Island.new(island_type, coordinate),
         %{} = board <- Board.position_island(board, island_type, island) do
      state
      |> update_board(player, board)
      |> update_rules(rules)
      |> reply_sucess(:ok)
    else
      :error -> {:reply, :error, state}
      {:error, :invalid_coordinate} -> {:reply, {:error, :invalid_coordinate}, state}
      {:error, :invalid_island_type} -> {:reply, {:error, :invalid_island_type}, state}
      {:error, :overlapping_islands} -> {:reply, {:error, :overlapping_islands}, state}
    end
  end

  def handle_call({:set_islands, player}, _from, state) do
    board = player_board(state, player)

    with {:ok, rules} <- Rules.check(state.rules, {:set_islands, player}),
         true <- Board.all_islands_positioned?(board) do
      state
      |> update_rules(rules)
      |> reply_sucess({:ok, board})
    else
      :error -> {:reply, :error, state}
      false -> {:reply, {:error, :not_all_islands_positioned}, state}
    end
  end

  def handle_call({:guess_coordinate, player, row, col}, _from, state) do
    opponent_key = opponent(player)
    opponent_board = player_board(state, opponent_key)

    with {:ok, rules} <- Rules.check(state.rules, {:guess_coordinate, player}),
         {:ok, coordinate} <- Coordinate.new(row, col),
         {hit_or_miss, forested_island, win_or_not, opponent_board} <-
           Board.guess(opponent_board, coordinate),
         {:ok, rules} <- Rules.check(rules, {:win_check, win_or_not}) do
      state
      |> update_board(opponent_key, opponent_board)
      |> update_guesses(player, hit_or_miss, coordinate)
      |> update_rules(rules)
      |> reply_sucess({:ok, hit_or_miss, forested_island, win_or_not})
    else
      :error -> {:reply, :error, state}
      {:error, :invalid_coordinate} -> {:reply, {:error, :invalid_coordinate}, state}
    end
  end

  defp update_player2_name(state, name) do
    put_in(state.player2.name, name)
  end

  defp update_rules(state, rules), do: Map.put(state, :rules, rules)

  defp reply_sucess(state, reply), do: {:reply, reply, state}

  defp update_board(state, player, board) do
    Map.update!(state, player, fn player -> %{player | board: board} end)
  end

  defp update_guesses(state, player, hit_or_miss, coordinate) do
    update_in(state[player].guesses, fn guesses ->
      Guesses.add_guess(guesses, hit_or_miss, coordinate)
    end)
  end

  defp player_board(state, player), do: Map.get(state, player).board

  defp opponent(:player1), do: :player2
  defp opponent(:player2), do: :player1
end
