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
         :ok <- validate_special(move, board, turn, history),
         :ok <- king_safe?(move, board, turn),
         {:ok, new_board} <- Board.apply_move(board, move)

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

  defp resolve_move(square_from, %Move{from: from, to: to}, board) do
    all_moves =
      [&Piece.moves/2, &Piece.attacks/2]
      |> Enum.flat_map(fn check_fun -> check_fun.(square_from, board) end)

    IO.inspect(all_moves, label: "all generated legal moves")

    case Enum.find(all_moves, fn %Move{from: ^from, to: ^to} -> true; _ -> false end) do
      nil -> {:error, :illegal_move}
      move -> {:ok, move}
    end
  end


  defp king_safe?(%Move{} = move, %Board{} = board, color) do
    case Board.apply_move(board, move) do
      {:ok, new_board} ->
        case not king_in_check?(new_board, color) do
          true -> :ok
          false -> {:error, :king_in_check}
        end

      {:error, reason} ->
        {:error,reason}
    end
  end


  defp king_in_check?(%Board{squares: squares} = board, color) do
    king_piece = if color == :white, do: :k, else: :K

    king_pos =
      Enum.find_value(squares, fn {pos, %Square{piece: p}} ->
        if p == king_piece, do: pos, else: nil
      end)

    Enum.any?(squares, fn
      {_pos, %Square{piece: nil}} -> false
      {_pos, %Square{piece: p} = square} ->
        PiecesLib.color_of(p) != color and
          Enum.any?(Piece.attacks(square, board), fn
            %Move{to: ^king_pos} -> true
            _ -> false
          end)
    end)
  end

  defp validate_special(%Move{castle: side} = move, board, turn, history) when not is_nil(side) do
    validate_castling(move, board, turn, history)
  end

  defp validate_special(_move, _board, _turn, _history), do: :ok


  defp validate_castling(move, board, turn, history) do

  end
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
