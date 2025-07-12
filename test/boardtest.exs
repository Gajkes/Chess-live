defmodule Chess.BoardTest  do
  use ExUnit.Case  # Import test framework
  alias Chess.{Board, Square}

  test "board is valid map of squares" do
    %Board{squares: board} = Chess.Board.new() # Or however your board is initialized

    assert is_map(board)

    Enum.each(board, fn
      {{row, col}, %Square{} = square} ->
        assert is_integer(row)
        assert is_atom(col)
        assert square.row == row
        assert square.column == col

      _ ->
        flunk("Board contains invalid key or value")
    end)
  end

  defp printer([h | t]) do
    case is_list(h) do
      true -> print_list(h)
      _ -> IO.puts("NOT LIST!")
            IO.inspect(h)
    end


    #IO.inspect(h.row)
    IO.puts("\n")
    printer(t)
 end

  defp printer([]) do
    IO.puts("END!!!!!!!")
  end
  defp print_list([]) do
    IO.puts("\n")
  end
  defp print_list([h|t]) do
    IO.inspect(h)
    print_list(t)
  end
end
