defmodule Chess.Board do

  require Logger
  require MyLogger
  alias Chess.Board
  alias Chess.Square
  alias Chess.Move

  defstruct squares: [%Square{}]
  def new() do
    initiate_board()
  end

  def apply_move(%Board{squares: squares} = board, %Move{} = move) do

    {:ok, {piece, squares_after_removal}} = remove_piece(squares, move)
    {_capture_orok, squares_after_move} = place_piece(squares_after_removal, move, piece)

    {:ok, %Board{squares: Map.new(squares_after_move)}}
  end

  defp remove_piece(squares, %Move{from: {row_from, col_from}} = move) do
    case  Map.get_and_update(squares, {row_from, col_from}, fn current ->
      {current, %Square{current | piece: nil}}
      end) do
        {%Square{piece: nil}, _} -> {:error, :empty_square}
        {%Square{piece: p}, updated_squares} ->
          {:ok, {p, updated_squares}}
      end
  end

  defp place_piece(squares, %Move{to: {row_to, col_to}}, piece) do
    case Map.get_and_update(squares, {row_to, col_to}, fn current ->
      {current, %Square{current | piece: piece}}
    end) do
      {%Square{piece: nil}, squares_after_move} -> {:ok, squares_after_move}
      {%Square{piece: _p}, squares_after_move} -> {:capture, squares_after_move} ##TODO handle capture here?
    end
  end


  defp initiate_board()  do
    squares =                               ##BOARD LOOKS LIKE THIS     COLUMN        A          B           C
     create_pieces(%{}, 1, pieces_white())   ###                     1st ROW    [  [%Square1,  %Square2,   %Square3,  ...... ],
     |> create_pawns(2, :p)                 ###                     2nd ROW       [%Square{9,   %Square10,    %Square11,  .... ],
     |> create_empty_squares()              ###                                   ....      ....
     |> create_pawns(7, :P)                 ###                                   ....           ...
     |> create_pieces(8, pieces_black())    ###                                   .....               ....                 %Square64   ]

    %Board{squares: squares}

  end
  defp create_empty_squares(squares) do
    empty_squares = Enum.into(for row <- 3..6, col <- columns() do
     { {row,col}, %Square{row: row, column: col, piece: nil, loc: {row,col}} }
    end, %{})
    Map.merge(squares,empty_squares)

  end
  defp create_pawns(squares, row, piece) do
    pawns = for col <- columns(), into: %{} do
      key = {row,col}
      {key, %Square{row: row, column: col, piece: piece, loc: key}}
    end
    Map.merge(squares,pawns)
  end
  defp create_pieces(squares, row, pieces) do
    fields = Enum.zip([columns(), pieces])
    map1 = for {column,piece} <- fields, into: %{} do
      key = {row, column}
      {key, %Square{row: row, column: column, piece: piece, loc: key}}
    end
    Map.merge(squares,map1)
  end

  defp columns() do
    [:a,:b,:c,:d,:e,:f,:g,:h]
  end

  defp pieces_white() do
    [:r,:n,:b,:q,:k,:b,:n,:r]
  end
  defp pieces_black() do
    [:R,:N,:B,:Q,:K,:B,:N,:R]
  end



end
