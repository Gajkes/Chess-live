defmodule ChessWeb.Chesslive do

      alias Chess.Move
  use ChessWeb, :live_view
  alias Chess.Board
  alias Chess.Game
  alias Chess.Square


  def mount(_params, _session, socket) do
    game = Game.new()

    {:ok,
     assign(socket, %{
       game: game,
       clicked_square: {nil, nil},
       pending_promotion: nil
     })}
  end

  def render(%{game: game, clicked_square: clicked, pending_promotion: promotion} = assigns) do
    ~H"""
    <div class="flex flex-col items-center space-y-6 mt-10">
      <div class="chessboard">
        <%= for row <- 1..8, col <- [:a, :b, :c, :d, :e, :f, :g, :h] do %>
          <.square square={Map.get(@game.board.squares, {row, col})} row_index={row} col_index={Chess.Pieces.PiecesLib.col_to_index(col) + 1} />
        <% end %>
      </div>

      <%= if @pending_promotion do %>
        <div class="p-4 bg-white border rounded shadow flex flex-col items-center">
          <h3 class="mb-2 font-bold text-lg">Choose a piece to promote to:</h3>
          <div class="flex gap-3">
            <%= for piece <- promotion_options(@pending_promotion.piece) do %>
              <button
                phx-click="promote"
                phx-value-piece={piece}
                class="w-[65px] h-[65px] border rounded hover:scale-105 transition"
              >
                <.piece piece={piece} class="w-[65px] h-[65px]" />
              </button>
            <% end %>
          </div>
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
  attr(:row_index, :integer, required: true)
  attr(:col_index, :integer, required: true)

  def square(assigns) do
    color =
      if rem(assigns.row_index + assigns.col_index, 2) == 0,
        do: "bg-[#1d2939]", # dark square
        else: "bg-white"

    assigns = assign(assigns, :color, color)

    ~H"""
    <div
      class={["square", @color]}
      phx-click="square-click"
      phx-value-column={@square.column}
      phx-value-row={@square.row}
    >
      <%= if @square.piece do %>
        <.piece piece={@square.piece} class="w-[65px] h-[65px]" />
      <% end %>
    </div>
    """
  end



  def handle_event("square-click", %{"column" => col, "row" => row}, socket) do
    column = String.to_atom(col)
    row = String.to_integer(row)
    game = socket.assigns.game
    clicked = socket.assigns.clicked_square

    case clicked do
      {nil, nil} ->
        {:noreply, assign(socket, clicked_square: {row, column})}

      from ->
        case Game.move(game, %Move{from: from, to: {row, column}}) do
          %Game{} = updated_game ->
            {:noreply, assign(socket, game: updated_game, clicked_square: {nil, nil})}

          {:promotion_pending, move} ->
            {:noreply, assign(socket, pending_promotion: move, clicked_square: {nil, nil})}

          _ ->
            {:noreply, assign(socket, clicked_square: {nil, nil})}
        end
    end
  end

  def handle_event("promote", %{"piece" => raw_piece}, socket) do
    move = socket.assigns.pending_promotion
    piece = String.to_existing_atom(raw_piece)

    case Game.move(socket.assigns.game, %Move{move | promotion: piece}) do
      %Game{} = updated_game ->
        IO.puts("here1")
        {:noreply, assign(socket, game: updated_game, pending_promotion: nil)}

      _ ->
        IO.puts("here2")
        {:noreply, socket}
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

  defp promotion_options(:p), do: [:q, :r, :b, :n]
  defp promotion_options(:P), do: [:Q, :R, :B, :N]
  defp promotion_options(_), do: []


end
