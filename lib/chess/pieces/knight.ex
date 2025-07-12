defmodule Chess.Pieces.Knight do
  @behaviour Chess.Piece

  import Chess.Pieces.PiecesLib
  alias Chess.Square
  alias Chess.Board
  alias Chess.MoveBuilder

  @directions [
    {2, 1}, {1, 2}, {-1, 2}, {-2, 1},
    {-2, -1}, {-1, -2}, {1, -2}, {2, -1}
  ]

  @impl true
  def moves(%Square{row: row, column: col} = square, %Board{squares: squares}) do

    generate_all_paths(square.loc,  @directions, 1)
    |> MoveBuilder.build_moves(square, squares)
  end

  @impl true
  def attacks(square, board), do: moves(square, board)
end
