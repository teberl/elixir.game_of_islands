defmodule IslandsEngine.Coordinate do
  @moduledoc """
  Coordinate are the basic units of both players’ boards and of islands.
  Individual coordinates can be identified by the combination of numbers for the row and the column.
  Coordinates can be only created in the @board_range 1..10

  iex> %IslandsEngine.Coordinate{row: 1, col: 1}
  """
  alias __MODULE__

  @board_range 1..10

  @typedoc """
    Coordinate are the basic units of both players’ boards and of islands.
    [:row, :col]
  """
  @type t :: %__MODULE__{row: 1..10, col: 1..10}

  @enforce_keys [:row, :col]
  defstruct [:row, :col]

  @doc """
  new/2 creates a new coordinate defstruct with the fields

  iex> IslandsEngine.Coordinate.new(1, 1)
  {:ok, %IslandsEngine.Coordinate{col: 1, row: 1}}

  iex> IslandsEngine.Coordinate.new(-1, ​​1)
  {:error, :invalid_coordinate}
  """
  @spec new(1..10, 1..10) :: {:error, :invalid_coordinate} | {:ok, %Coordinate{}}
  def new(row, col) when row in @board_range and col in @board_range do
    {:ok, %Coordinate{row: row, col: col}}
  end

  def new(_row, _col), do: {:error, :invalid_coordinate}
end
