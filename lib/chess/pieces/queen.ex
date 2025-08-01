defmodule Chess.Pieces.Queen do
  @behaviour Chess.Piece

  import Chess.Pieces.PiecesLib
  alias Chess.Square
  alias Chess.Board
  alias Chess.MoveBuilder

  @impl true
  def moves(%Square{row: row, column: col} = square, %Board{squares: squares}) do
    directions = [
      # Rook directions
      {1, 0},
      {-1, 0},
      {0, 1},
      {0, -1},
      # Bishop directions
      {1, 1},
      {1, -1},
      {-1, 1},
      {-1, -1}
    ]

    generate_all_paths(square.loc, directions)
    |> MoveBuilder.build_moves(square, squares)
  end

  @impl true
  def attacks(square, board), do: moves(square, board) |> Enum.filter(& &1.capture)
end
