defmodule Chess.MoveBuilder do
  alias Chess.{Square, Move}
  import Chess.Pieces.PiecesLib, only: [index_to_col: 1, is_enemy?: 2]


  def build_moves(paths, %Square{loc: from, piece: piece}, squares) do
    paths
    |> Enum.reduce([], fn path, acc1 ->
        Enum.reduce_while(path, acc1, fn {r, c_index}, acc ->
          col = index_to_col(c_index)
          pos = {r, col}
          case Map.get(squares, pos) do
            %Square{piece: nil} -> {:cont, acc ++ [%Move{from: from, to: pos, capture: false}]}
            %Square{piece: target} ->
                 if is_enemy?(target, piece) do
                  {:halt, acc ++ [%Move{from: from, to: pos, capture: true}]}
                 else
                  {:halt, acc}
                 end
            _ ->
              {:halt, acc}
          end
        end)
      end)
  end


end
