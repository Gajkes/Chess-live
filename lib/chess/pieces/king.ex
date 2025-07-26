defmodule Chess.Pieces.King do
  @behaviour Chess.Piece

  @directions [
    # rook-like
    {1, 0},
    {-1, 0},
    {0, 1},
    {0, -1},
    # bishop-like
    {1, 1},
    {1, -1},
    {-1, 1},
    {-1, -1}
  ]
  import Chess.Pieces.PiecesLib
  alias Chess.Square
  alias Chess.Board
  alias Chess.Move
  alias Chess.MoveBuilder

  @impl true
  def moves(%Square{piece: :k, loc: {1, :e}} = square, %Board{squares: squares} = board) do
    regular =
      generate_all_paths(square.loc, @directions, 1)
      |> MoveBuilder.build_moves(square, squares)

    castle = castle_moves(:white, square, squares)

    regular ++ castle
  end

  def moves(%Square{piece: :K, loc: {8, :e}} = square, %Board{squares: squares} = board) do
    regular =
      generate_all_paths(square.loc, @directions, 1)
      |> MoveBuilder.build_moves(square, squares)

    castle = castle_moves(:black, square, squares)

    regular ++ castle
  end

  def moves(%Square{row: row, column: col} = square, %Board{squares: squares}) do
    generate_all_paths(square.loc, @directions, 1)
    |> MoveBuilder.build_moves(square, squares)
  end

  @impl true
  def attacks(square, board), do: moves(square, board) |> Enum.filter(& &1.capture)

  defp castle_moves(color, %Square{loc: {row, :e}, piece: king_piece}, squares)
       when (color == :black and king_piece == :K) or
              (color == :white and king_piece == :k) do
    [
      castle_option(row, {row, :h}, [:f, :g], {row, :g}, :kingside, color, squares),
      castle_option(row, {row, :a}, [:d, :c, :b], {row, :c}, :queenside, color, squares)
    ]
    |> Enum.filter(& &1)
  end

  defp castle_option(row, rook_pos, empty_cols, king_target_pos, side, color, squares) do
    rook_piece = if color == :black, do: :R, else: :r

    rook_on_place? =
      case Map.get(squares, rook_pos) do
        %Square{piece: ^rook_piece} -> true
        _ -> false
      end

    empty_space? =
      Enum.all?(empty_cols, fn col ->
        Map.get(squares, {row, col}) |> then(&(&1.piece == nil))
      end)

    if rook_on_place? and empty_space? do
      %Move{from: {row, :e}, to: king_target_pos, castle: side}
    else
      nil
    end
  end
end
