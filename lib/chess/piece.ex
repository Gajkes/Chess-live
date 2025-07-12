defmodule Chess.Piece do
  alias Chess.Square

  @callback moves(Square.t(), Board.t()) :: [Move.t()]
  @callback attacks(Square.t(), Board.t()) :: [Move.t()]


  @pieces_map %{
    p: Chess.Pieces.Pawn,
    P: Chess.Pieces.Pawn,
    n: Chess.Pieces.Knight,
    N: Chess.Pieces.Knight,
    b: Chess.Pieces.Bishop,
    B: Chess.Pieces.Bishop,
    r: Chess.Pieces.Rook,
    R: Chess.Pieces.Rook,
    q: Chess.Pieces.Queen,
    Q: Chess.Pieces.Queen,
    k: Chess.Pieces.King,
    K: Chess.Pieces.King
  }

  @spec module_for(atom()) :: module() | nil
  defp module_for(piece_atom) do
    Map.get(@pieces_map, piece_atom)
  end

  @spec moves(Square.t(), Board.t()) :: [Move.t()]
  def moves(%Square{piece: nil}, _board), do: []
  def moves(%Square{piece: piece} = square, board) do
    IO.inspect(piece, label: "piece moves")
    case module_for(piece) do
      nil -> []
      mod -> IO.inspect(mod, label: "piece moves mod")
        mod.moves(square, board)
    end
  end

  @spec attacks(Square.t(), Board.t()) :: [Move.t()]
  def attacks(%Square{piece: nil}, _board), do: []
  def attacks(%Square{piece: piece} = square, board) do
    IO.inspect(piece, label: "piece attacks")
    case module_for(piece) do
      nil ->
        []
      mod -> IO.inspect(mod, label: "piece attacks mod")
        mod.attacks(square, board)
    end
  end
end
