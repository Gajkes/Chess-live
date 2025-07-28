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

  def move(
        %Game{board: board, turn: turn, history: history} = game,
        %Move{from: {row, col}} = move
      ) do
    square_from = %Square{piece: piece} = Map.get(board.squares, {row, col})
    move = %Move{move | piece: piece}
    IO.inspect(move, label: "move from client")

    with :ok <- validate_turn(turn, move),
         {:ok, move} <- resolve_move(square_from, move, board),
         result <- validate_special(move, board, turn, history),
         {:ok, action} <- handle_move(result, game, turn) do
      case action do
        %Game{} = updated_game -> updated_game
        {:promotion_pending, move} -> {:promotion_pending, move}
      end
    else
      {:error, reason} ->
        IO.inspect(reason)
        game
    end
  end

  def possible_moves(%Game{board: board, turn: turn, history: history}, {row, col}) do
    # TODO maybe do better this function and move function duplicate code?
    square = %Square{piece: p} = Map.get(board.squares, {row, col})

    with :ok <- validate_turn(turn, p) do
      normal_moves =
        Piece.moves(square, board)
        |> List.flatten()
        |> Enum.filter(fn %Move{} = move ->
          move = %Move{move | piece: p}

          case {validate_special(move, board, turn, history), king_safe_all?(move, board, turn)} do
            {{:ok, _}, :ok} -> true
            _ -> false
          end
        end)

      attack_moves =
        Piece.attacks(square, board)
        |> List.flatten()
        |> Enum.filter(fn attack_move ->
          case king_safe_all?(attack_move, board, turn) do
            :ok -> true
            _ -> false
          end
        end)

      {normal_moves, attack_moves}
    else
      _ ->
        {[], []}
    end
  end

  defp handle_move({:ok, moves}, %Game{board: board} = game, turn) do
    with :ok <- king_safe_all?(moves, board, turn),
         {:ok, new_board} <- Board.apply_moves(board, moves) do
      {:ok,
       %Game{
         game
         | board: new_board,
           turn: opposite(turn),
           history: moves ++ game.history
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp handle_move({:promotion_pending, move}, %Game{board: board} = _game, turn) do
    with :ok <- king_safe_all?([move], board, turn) do
      {:ok, {:promotion_pending, move}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp handle_move({:error, reason}, _game, _turn), do: {:error, reason}

  def board(%Game{board: board}), do: board

  defp validate_turn(:white, %Move{piece: p}) when p in [:p, :n, :b, :r, :q, :k], do: :ok
  defp validate_turn(:black, %Move{piece: p}) when p in [:P, :N, :B, :R, :Q, :K], do: :ok
  defp validate_turn(:white, p) when p in [:p, :n, :b, :r, :q, :k], do: :ok
  defp validate_turn(:black, p) when p in [:P, :N, :B, :R, :Q, :K], do: :ok
  # TODO there is a bug
  defp validate_turn(_, _), do: {:error, :wrong_turn}

  defp opposite(:white), do: :black
  defp opposite(:black), do: :white

  defp resolve_move(
         square_from = %Square{piece: piece},
         %Move{from: from, to: to, promotion: promo},
         board
       ) do
    all_moves =
      [&Piece.moves/2, &Piece.attacks/2]
      |> Enum.flat_map(fn check_fun -> check_fun.(square_from, board) end)

    IO.inspect(all_moves, label: "all generated legal moves")

    case Enum.find(all_moves, fn
           %Move{from: ^from, to: ^to} -> true
           _ -> false
         end) do
      nil ->
        IO.puts("resolve_move {:error, :illegal_move}")
        {:error, :illegal_move}

      legal_move ->
        updated_move =
          %Move{
            legal_move
            | piece: piece,
              promotion: promo || legal_move.promotion
          }

        IO.inspect(updated_move, label: "resolve_move {:ok, updated_move}")
        {:ok, updated_move}
    end
  end

  defp king_safe_all?(%Move{} = move, board, color), do: king_safe_all?([move], board, color)

  defp king_safe_all?(moves, board, color) do
    case Board.apply_moves(board, moves) do
      {:ok, new_board} ->
        if king_in_check?(new_board, color), do: {:error, :king_in_check}, else: :ok

      {:error, reason} ->
        {:error, reason}
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

  defp validate_special(move, board, turn, history) do
    case resolve_special(move, board, turn, history) do
      {:ok, moves} -> {:ok, moves}
      {:promotion_pending, move} -> {:promotion_pending, move}
      {:error, reason} -> {:error, reason}
    end
  end

  defp resolve_special(%Move{castle: side, piece: piece} = move, board, turn, history)
       when not is_nil(side) do
    case validate_castling(move, board, turn, history) do
      :ok ->
        {row, _} = move.from

        rook_piece =
          case piece do
            :k -> :r
            :K -> :R
          end

        rook_move =
          case side do
            :kingside -> %Move{from: {row, :h}, to: {row, :f}, piece: rook_piece}
            :queenside -> %Move{from: {row, :a}, to: {row, :d}, piece: rook_piece}
          end

        {:ok, [move, rook_move]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # pawn promotion
  defp resolve_special(%Move{piece: :p, to: {8, _}} = move, _board, _turn, _history) do
    handle_promotion(move, :white)
  end

  defp resolve_special(%Move{piece: :P, to: {1, _}} = move, _board, _turn, _history) do
    handle_promotion(move, :black)
  end

  defp resolve_special(%Move{en_passant: true} = move, board, turn, history) do
    case validate_en_passant(move, board, turn, hd(history)) do
      :ok ->
        # Create a move to remove the captured pawn
        captured_pawn_pos = PiecesLib.get_en_passant_captured_pawn_pos(move, turn)

        remove_pawn_move = %Move{
          from: captured_pawn_pos,
          to: captured_pawn_pos,
          piece: nil,
          capture: nil,
          en_passant: :captured
        }

        {:ok, [move, remove_pawn_move]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp resolve_special(move, _board, _turn, _history), do: {:ok, [move]}

  defp handle_promotion(%Move{promotion: nil} = move, _color) do
    {:promotion_pending, move}
  end

  defp handle_promotion(%Move{promotion: piece} = move, :white)
       when piece in [:q, :r, :b, :n] do
    {:ok, [%Move{move | piece: piece}]}
  end

  defp handle_promotion(%Move{promotion: piece} = move, :black)
       when piece in [:Q, :R, :B, :N] do
    {:ok, [%Move{move | piece: piece}]}
  end

  defp handle_promotion(_move, _), do: {:error, :invalid_promotion_choice}

  ## validate castling from game perspective
  ## Neither the king nor the rook involved has moved yet in the game.
  ## The king does not move through a square that is attacked by an opponent's piece.
  defp validate_castling(
         %Move{castle: side, from: {row, :e}, piece: piece},
         board,
         _turn,
         history
       )
       when not is_nil(side) and piece in [:k, :K] do
    {color, rook} =
      case piece do
        :k -> {:white, :r}
        :K -> {:black, :R}
      end

    rook_col = if side == :kingside, do: :h, else: :a
    rook_pos = {row, rook_col}

    if has_moved_before?({row, :e}, history) or has_moved_before?(rook_pos, history) do
      {:error, :moved_before}
    else
      path =
        case side do
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

  defp validate_en_passant(
         %Move{from: {from_row, from_col}, to: {to_row, to_col}, piece: piece},
         board,
         turn,
         last_move
       ) do
    unless piece in [:p, :P] do
      {:error, :not_a_pawn}
    end

    IO.inspect(last_move, label: "en passant last move")
    IO.inspect(to_col, label: "Want to move to col:")

    case last_move do
      %Move{piece: enemy_piece, from: {enemy_from_row, enemy_col}, to: {enemy_to_row, enemy_col}}
      when enemy_piece in [:p, :P] ->
        two_square_move? = abs(enemy_from_row - enemy_to_row) == 2

        adjacent? =
          abs(PiecesLib.col_to_index(enemy_col) - PiecesLib.col_to_index(from_col)) == 1 and
            enemy_to_row == from_row

        IO.inspect(enemy_col, label: "Enemy last col move:")

        correct_target? =
          case turn do
            :white -> to_row == from_row + 1 and enemy_to_row == 5 and enemy_col == to_col
            :black -> to_row == from_row - 1 and enemy_to_row == 4 and enemy_col == to_col
          end

        if two_square_move? and adjacent? and correct_target? do
          :ok
        else
          {:error, :invalid_en_passant}
        end

      _ ->
        {:error, :no_valid_en_passant_opportunity}
    end
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
