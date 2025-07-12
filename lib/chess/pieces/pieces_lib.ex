defmodule Chess.Pieces.PiecesLib do
  alias Chess.Square
  @columns [:a, :b, :c, :d, :e, :f, :g, :h]
  @col_to_index Enum.with_index(@columns) |> Map.new()
  @index_to_col Enum.with_index(@columns) |> Enum.into(%{}, fn {col, i} -> {i, col} end)

  # === Column Helpers ===
  def col_to_index(col), do: Map.get(@col_to_index, col)
  def index_to_col(i), do: Map.get(@index_to_col, i)

  def shift_column(col, offset) when col in @columns do
    index = col_to_index(col)
    Enum.at(@columns, index + offset)
  end

  # === Raw Path Generator ===
  def generate_paths({row, col}, {dr, dc}, max_steps \\ 8) do
    col_index = col_to_index(col)

    Stream.iterate({row + dr, col_index + dc}, fn {r, c} ->
      {r + dr, c + dc}
    end)
    |> Enum.take(max_steps)
    |> Enum.take_while(fn {r, c} -> r in 1..8 and c in 0..7 end)
  end

  def generate_all_paths(start_pos, directions, max_steps \\ 8) do
    Enum.map(directions, fn dir -> generate_paths(start_pos, dir, max_steps) end)
  end

  def color_of(piece) when is_atom(piece) do
    if piece in [:p, :r, :n, :b, :q, :k], do: :white, else: :black
  end

  def is_enemy?(nil, _), do: false
  def is_enemy?(_, nil), do: false
  def is_enemy?(a, b), do: color_of(a) != color_of(b)
  # === General Utilities ===
  # def valid_squares(path) do
  #   Enum.filter(path, fn {r, c_index} -> r in 1..8 and c_index in 0..7 end)
  # end
  def square_attacked?(target_pos, %Chess.Board{squares: squares} = board, attacker_color) do
    Enum.any?(squares, fn
      {_pos, %Chess.Square{piece: nil}} -> false
      {_pos, %Chess.Square{piece: p} = square} ->
        color_of(p) == attacker_color and
          Enum.any?(Chess.Piece.attacks(square, board), fn
            %Chess.Move{to: ^target_pos} -> true
            _ -> false
          end)
    end)
  end

end
