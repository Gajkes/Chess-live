defmodule Chess.Pieces.Pawn do
  @behaviour Chess.Piece

  import Chess.Pieces.PiecesLib,
    only: [generate_all_paths: 3, generate_all_paths: 3, index_to_col: 1, is_enemy?: 2]

  alias Chess.{Board, Move, Square}
  alias Chess.MoveBuilder

  @impl true
  def moves(%Square{row: 2} = square, %Board{squares: squares}) do
    # Try one-step forward first
    single_moves = generate_all_paths(square.loc, [{1, 0}], 1)
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

  def moves(%Square{piece: :p} = square, %Board{squares: squares}) do
   generate_all_paths(square.loc, [{1, 0}], 1)
   |> MoveBuilder.build_moves(square, squares)
   |> Enum.filter(fn %Move{capture: capture} -> not capture end)
  end

  def moves(%Square{row: 7} = square, %Board{squares: squares}) do
    single_moves = generate_all_paths(square.loc, [{-1, 0}], 1)
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
        _ -> acc
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
        _ -> acc
      end
    end)
  end
end
