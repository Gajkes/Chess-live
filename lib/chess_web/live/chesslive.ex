defmodule ChessWeb.Chesslive do

      alias Chess.Move
  use ChessWeb, :live_view
  alias Chess.Board
  alias Chess.Game
  alias Chess.Square


  def mount(params, session, socket) do
    game = Game.new()
    {:ok, assign(socket, %{game: game, clicked_square: {nil,nil}})}
  end

  def render(%{game: game} = assigns) do
    # %Board{squares: board} = game.board

    # IO.inspect(Map.get(board,{1,:a}), label: "square 1-a")
    # IO.inspect(Map.get(board,{3,:a}), label: "square 3-a")

    ~H"""
    <div class="chessboard">
      <%= for row <- 1..8 do %>
        <div class="row flex">
          <%= for {col, col_index} <- Enum.with_index([:a, :b, :c, :d, :e, :f, :g, :h], 1) do  %>
            <.square square = {Map.get(@game.board.squares,{row,col})} row_index={row} col_index={col_index} key={"#{row}-#{col}"} />
            <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  attr(:piece, :atom)
  attr(:class, :string, default: "")

  #def piece (%{piece: nil} = assigns), do: ~H""
  def piece(assigns) do
    if assigns[:piece] == nil do
      ~H""
    else
    ~H"""
    <span class={[piece_name(@piece), @class]} />
    """
    end
  end

  attr(:square, Square)
  attr(:click_type, :atom, values: [:select,:move])
  attr( :row_index, :integer, required: true)
  attr( :col_index, :integer, required: true)
  def square(assigns) do
    color = if rem(assigns.row_index + assigns.col_index, 2) == 0, do: "bg-gray-800", else: "bg-red"
    assigns = assign(assigns, :color, color)

    ~H"""
    <div
      class={[
                "square w-[80px] h-[80px] flex items-center justify-center", @color
              ]}
      phx-click="square-click"
      phx-value-column = {@square.column}
      phx-value-row = {@square.row}
    >
    <%= if @square.piece do %>
      <.piece piece={@square.piece} class="w-[65px] h-[65px] mt-[1.5px]" />
    <% end %>
    </div>
    """
  end

  def handle_event("square-click", %{"column" => column, "row" => row}, socket) do

    ##check if this is possible to make move here?
    ##if new piece is clicked change clicked piece
    old_clicked_square = socket.assigns.clicked_square
    old_game = socket.assigns.game
    column = String.to_atom(column)
    row = String.to_integer(row)
    if  old_clicked_square != {nil, nil} do
        new_game = Game.move(old_game, %Move{from: old_clicked_square, to: {row, column}}) #TODO move this if to pattern matching #TODO bug with clicked square
        {:noreply, assign(socket, %{game: new_game , clicked_square: {nil, nil}})}
    else
      {:noreply, assign(socket, %{game: socket.assigns.game , clicked_square: {row, column}})}
    end
  end






  def piece_name(:p), do: "piece-white-pawn"
  def piece_name(:P), do: "piece-black-pawn"
  def piece_name(:n), do: "piece-white-knight"
  def piece_name(:N), do: "piece-black-knight"
  def piece_name(:b), do: "piece-white-bishop"
  def piece_name(:B), do: "piece-black-bishop"
  def piece_name(:r), do: "piece-white-rook"
  def piece_name(:R), do: "piece-black-rook"
  def piece_name(:q), do: "piece-white-queen"
  def piece_name(:Q), do: "piece-white-queen"
  def piece_name(:k), do: "piece-white-king"
  def piece_name(:K), do: "piece-black-king"
  def piece_name(nil), do: ""


end
