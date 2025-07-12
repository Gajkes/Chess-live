defmodule Chess.Pieces.Bishop do
  @behaviour Chess.Piece

  import Chess.Pieces.PiecesLib
  alias Chess.Square
  alias Chess.Board
  alias Chess.MoveBuilder

  @impl true
  def moves(%Square{loc: loc} = square, %Board{squares: squares}) do
    directions = [
      {1, 1},   # down-right
      {-1, -1}, # up-left
      {-1, 1},  # up-right
      {1, -1}   # down-left
    ]

    generate_all_paths(square.loc, directions)
    |> MoveBuilder.build_moves(square, squares)

  end

  @impl true
  def attacks(square, board), do: moves(square, board)
end
