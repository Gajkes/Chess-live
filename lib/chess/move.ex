import Chess.Piece


defmodule Chess.Move do
  defstruct from: {},
            to: {},
            piece: nil,
            capture: nil,
            promotion: nil,
            castle: nil,
            en_passant: nil
            # checking: nil


end
