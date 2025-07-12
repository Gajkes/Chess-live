defmodule Chess.Game do
  alias Chess.Pieces.PiecesLib
  alias Chess.Piece
  alias Chess.Board
  alias Chess.Game
  alias Chess.Move
  alias Chess.Square

  defstruct board: %Board{},
            turn: :white,
            history: []


  def new() do
    %Game{board: Board.new(), turn: :white, history: []}
  end


  def move(%Game{board: board, turn: turn, history: history} = game, %Move{from: {row, col}} = move) do

    square_from = %Square{piece: piece} = Map.get(board.squares, {row,col})
    move = %Move{move | piece: piece}

    with :ok <- validate_turn(turn, move),
         {:ok, move} <- resolve_move(square_from, move, board),
         {:ok, moves} <- validate_special(move, board, turn, history),
         :ok <- king_safe_all?(moves, board, turn),
         {:ok, new_board} <- Board.apply_moves(board, moves)

         do
          %Game{
            game
            | board: new_board,
              turn: opposite(turn),
              history: [move | history]
          }
    else
      {:error, reason} ->
        IO.inspect(reason)
        game
    end
  end


  def board(%Game{board: board}), do: board

  defp validate_turn(:white, %Move{piece: p}) when p in [:p, :n, :b, :r, :q, :k], do: :ok
  defp validate_turn(:black, %Move{piece: p}) when p in [:P, :N, :B, :R, :Q, :K], do: :ok
  defp validate_turn(_, _), do: {:error, :wrong_turn}

  defp opposite(:white), do: :black
  defp opposite(:black), do: :white

  defp resolve_move(square_from = %Square{piece: piece}, %Move{from: from, to: to}, board) do
    all_moves =
      [&Piece.moves/2, &Piece.attacks/2]
      |> Enum.flat_map(fn check_fun -> check_fun.(square_from, board) end)

    IO.inspect(all_moves, label: "all generated legal moves")

    case Enum.find(all_moves, fn %Move{from: ^from, to: ^to} -> true; _ -> false end) do
      nil ->
        IO.puts("resolve_move {:error, :illegal_move}")
        {:error, :illegal_move}
      move ->
        updated_move = %Move{move | piece: piece}
        IO.inspect(updated_move, label: "resolve_move {:ok, move}")
        {:ok, updated_move}
    end
  end


  defp king_safe_all?(moves, board, color) do
    case Board.apply_moves(board, moves) do
      {:ok, new_board} ->
        if king_in_check?(new_board, color), do: {:error, :king_in_check}, else: :ok

      {:error, reason} -> {:error, reason}
    end
  end


  defp king_in_check?(%Board{squares: squares} = board, color) do
    king_piece = if color == :white, do: :k, else: :K

    case Enum.find_value(squares, fn {pos, %Square{piece: p}} ->
      if p == king_piece, do: pos, else: nil
    end) do
    nil -> false
    king_pos -> PiecesLib.square_attacked?(king_pos, board, opposite(color))
 end
  end

  defp validate_special(move, board, turn, history)  do
    case resolve_special(move, board, turn, history) do
      {:ok, moves} -> {:ok, moves}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_special(_move, _board, _turn, _history), do: :ok

  defp resolve_special(%Move{castle: side} = move, board, turn, history) when not is_nil(side) do
    case validate_castling(move, board, turn, history) do
      :ok ->
        {row, _} = move.from

        rook_move =
          case side do
            :kingside -> %Move{from: {row, :h}, to: {row, :f}}
            :queenside -> %Move{from: {row, :a}, to: {row, :d}}
          end

        {:ok, [move, rook_move]}

      {:error, reason} -> {:error, reason}
    end
  end

  # Placeholder for future special cases
  defp resolve_special(move, _board, _turn, _history), do: {:ok, [move]}

  ## validate castling from game perspective
  ## Neither the king nor the rook involved has moved yet in the game.
  ## The king does not move through a square that is attacked by an opponent's piece.
defp validate_castling(%Move{castle: side, from: {row, :e}, piece: piece}, board, _turn, history)
     when not is_nil(side) and piece in [:k, :K] do

  {color, rook_piece} =
    case piece do
      :k -> {:white, :r}
      :K -> {:black, :R}
    end

  rook_col = if side == :kingside, do: :h, else: :a
  rook_pos = {row, rook_col}

  if has_moved_before?({row, :e}, history) or has_moved_before?(rook_pos, history) do
    {:error, :moved_before}
  else
      path = case side do
        :kingside -> [{row, :f}, {row, :g}]
        :queenside -> [{row, :d}, {row, :c}]
      end

      squares_to_check = [{row, :e} | path]
      opponent = opposite(color)

      if Enum.any?(squares_to_check, fn pos ->
            PiecesLib.square_attacked?(pos, board, opponent)
          end) do
        {:error, :in_check_or_through_check}
      else
        :ok
      end
  end
end

defp validate_castling(_move, _board, _turn, _history), do: :ok


  def history(%Game{history: history}), do: Enum.reverse(history)

  @doc """
  Checks if a piece at `pos` has moved before (was the source of any move).
  """
  @spec has_moved_before?({integer(), atom()}, [Move.t()]) :: boolean()
  def has_moved_before?(pos, history) do
    Enum.any?(history, fn
      %Move{from: ^pos} -> true
      _ -> false
    end)
  end

end
