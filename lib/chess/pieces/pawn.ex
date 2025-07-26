defmodule Chess.Pieces.Pawn do
  @behaviour Chess.Piece

  import Chess.Pieces.PiecesLib,
    only: [generate_all_paths: 3, index_to_col: 1, is_enemy?: 2, shif_column: 2]

  alias Chess.Pieces.PiecesLib
  alias Chess.{Board, Move, Square}
  alias Chess.MoveBuilder

  # white pawn
  @impl true
  def moves(%Square{row: 2} = square, %Board{squares: squares}) do
    # Try one-step forward first
    single_moves =
      generate_all_paths(square.loc, [{1, 0}], 1)
      |> MoveBuilder.build_moves(square, squares)
      |> Enum.filter(fn %Move{capture: capture} -> not capture end)

    # Only generate double-step if the single-step square is free
    if Enum.empty?(single_moves) do
      []
    else
      generate_all_paths(square.loc, [{1, 0}], 2)
      |> MoveBuilder.build_moves(square, squares)
      |> Enum.filter(fn %Move{capture: capture} -> not capture end)
    end
  end

  def moves(%Square{piece: :p, row: 5} = square, %Board{squares: squares}) do
    # Regular forward moves
    forward_moves =
      generate_all_paths(square.loc, [{1, 0}], 1)
      |> MoveBuilder.build_moves(square, squares)
      |> Enum.filter(fn %Move{capture: capture} -> not capture end)

    # En passant moves for white pawns on 5th rank
    en_passant_moves = generate_en_passant_moves(square, squares, :white)

    forward_moves ++ en_passant_moves
  end

  def moves(%Square{piece: :P, row: 4} = square, %Board{squares: squares}) do
    # Regular forward moves
    forward_moves =
      generate_all_paths(square.loc, [{-1, 0}], 1)
      |> MoveBuilder.build_moves(square, squares)
      |> Enum.filter(fn %Move{capture: capture} -> not capture end)

    # En passant moves for black pawns on 4th rank
    en_passant_moves = generate_en_passant_moves(square, squares, :black)

    forward_moves ++ en_passant_moves
  end

  def moves(%Square{piece: :p} = square, %Board{squares: squares}) do
    generate_all_paths(square.loc, [{1, 0}], 1)
    |> MoveBuilder.build_moves(square, squares)
    |> Enum.filter(fn %Move{capture: capture} -> not capture end)
  end

  def moves(%Square{row: 7} = square, %Board{squares: squares}) do
    single_moves =
      generate_all_paths(square.loc, [{-1, 0}], 1)
      |> MoveBuilder.build_moves(square, squares)
      |> Enum.filter(fn %Move{capture: capture} -> not capture end)

    if Enum.empty?(single_moves) do
      []
    else
      generate_all_paths(square.loc, [{-1, 0}], 2)
      |> MoveBuilder.build_moves(square, squares)
      |> Enum.filter(fn %Move{capture: capture} -> not capture end)
    end
  end

  def moves(%Square{piece: :P} = square, %Board{squares: squares}) do
    generate_all_paths(square.loc, [{-1, 0}], 1)
    |> MoveBuilder.build_moves(square, squares)
    |> Enum.filter(fn %Move{capture: capture} -> not capture end)
  end

  @impl true
  def attacks(%Square{loc: from, piece: :p} = square, %Board{squares: squares}) do
    generate_all_paths(square.loc, [{1, -1}, {1, 1}], 1)
    |> List.flatten()
    |> Enum.reduce([], fn {r, c_index}, acc ->
      col = index_to_col(c_index)
      pos = {r, col}

      case Map.get(squares, pos) do
        %Square{piece: target} ->
          if is_enemy?(target, :p) do
            acc ++ [%Move{from: from, to: pos, capture: true}]
          else
            acc
          end

        _ ->
          acc
      end
    end)
  end

  def attacks(%Square{loc: from, piece: :P} = square, %Board{squares: squares}) do
    generate_all_paths(square.loc, [{-1, -1}, {-1, 1}], 1)
    |> List.flatten()
    |> Enum.reduce([], fn {r, c_index}, acc ->
      col = index_to_col(c_index)
      pos = {r, col}

      case Map.get(squares, pos) do
        %Square{piece: target} ->
          if is_enemy?(target, :P) do
            acc ++ [%Move{from: from, to: pos, capture: true}]
          else
            acc
          end

        _ ->
          acc
      end
    end)
  end

  defp generate_en_passant_moves(%Square{loc: {row, col}, piece: piece}, squares, color) do
    enemy_piece = if color == :white, do: :P, else: :p

    # Check adjacent columns for enemy pawns
    adjacent_cols =
      [PiecesLib.shift_column(col, -1), PiecesLib.shift_column(col, 1)]
      |> Enum.filter(&(&1 != nil))

    Enum.filter(
      adjacent_cols,
      fn enemy_col ->
        case Map.get(squares, {row, enemy_col}) do
          %Square{piece: ^enemy_piece} -> true
          _ -> false
        end
      end
    )
    |> Enum.map(fn enemy_col ->
      target_row = if color == :white, do: row + 1, else: row - 1

      %Move{
        from: {row, col},
        to: {target_row, enemy_col},
        piece: piece,
        capture: true,
        en_passant: true
      }
    end)
  end
end
