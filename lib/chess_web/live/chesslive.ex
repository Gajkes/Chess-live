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
       pending_promotion: nil,
       possible_moves: [],
       capture_moves: [],
       special_moves: []
     })}
  end

  def render(
        %{
          possible_moves: possible_moves,
          capture_moves: capture_moves,
          special_moves: special_moves
        } = assigns
      ) do
    ~H"""
    <div class="flex flex-col items-center space-y-6 mt-10">
      <div class="chessboard">
        <%= for row <- 8..1, col <- [:a, :b, :c, :d, :e, :f, :g, :h] do %>
          <%!-- <.square square={Map.get(@game.board.squares, {row, col})} row_index={row} col_index={Chess.Pieces.PiecesLib.col_to_index(col) + 1} /> --%>
          <.square
            square={Map.get(@game.board.squares, {row, col})}
            row_index={row}
            col_index={Chess.Pieces.PiecesLib.col_to_index(col) + 1}
            is_possible_move={Enum.member?(@possible_moves, {row, col})}
            is_capture={Enum.member?(@capture_moves, {row, col})}
            is_special_move={Enum.member?(@special_moves, {row, col})}
            clicked_square={@clicked_square}
          />
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

  # def piece (%{piece: nil} = assigns), do: ~H""
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
  attr(:is_possible_move, :boolean, default: false)
  attr(:is_capture, :boolean, default: false)
  attr(:is_special_move, :boolean, default: false)
  attr(:clicked_square, :any, default: {nil, nil})

  def square(assigns) do
    color =
      if rem(assigns.row_index + assigns.col_index, 2) == 0,
        do: "bg-[#a9745d]",
        else: "bg-white"

    # Blue outline if selected
    selected =
      assigns.clicked_square == {assigns.row_index, assigns.col_index} &&
        "outline outline-2 outline-blue-500 outline-offset-[-4px]"

    assigns = assign(assigns, :color, color)
    assigns = assign(assigns, :selected, selected)

    ~H"""
    <div
      class={[
        "square relative w-[65px] h-[65px] flex items-center justify-center",
        @color,
        @selected
      ]}
      phx-click="square-click"
      phx-value-column={@square.column}
      phx-value-row={@square.row}
    >
      <!-- Capture marker -->
      <%= if @is_capture do %>
        <div style="
            position: absolute;
            left: 50%; top: 50%;
            width: 48px; height: 48px;
            border: 4px solid #e3342f;
            border-radius: 50%;
            transform: translate(-50%, -50%);
            background: rgba(227,52,47,0.10);
            box-shadow: 0 0 12px 4px #e3342f55;
            z-index: 5;
          ">
        </div>
      <% end %>
      <!-- Special move dot -->
      <%= if !@is_capture && @is_special_move do %>
        <div style="
            position: absolute;
            left: 50%; top: 50%;
            width: 32px; height: 32px;
            background: rgba(66, 153, 225, 0.25);  /* Blue-ish */
            border-radius: 50%;
            transform: translate(-50%, -50%);
            box-shadow: 0 0 6px 2px #4299e155;
            z-index: 4;
          ">
        </div>
      <% end %>
      <!-- Normal move dot -->
      <%= if !@is_capture && !@is_special_move && @is_possible_move do %>
        <div style="
            position: absolute;
            left: 50%; top: 50%;
            width: 18px; height: 18px;
            background: rgba(255,255,255,0.8);
            border-radius: 50%;
            transform: translate(-50%, -50%);
            box-shadow: 0 0 4px 2px #0002;
            z-index: 3;
          ">
        </div>
      <% end %>
      <!-- The piece itself -->
      <%= if @square.piece do %>
        <.piece piece={@square.piece} class="w-[55px] h-[55px] z-10" />
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
        {possible_moves, capture_moves, special_moves} =
          Game.possible_moves(game, {row, column})
          |> then(fn {pm, cm} ->
            pm_tuples = Enum.map(pm, fn %Move{to: {row, col}} -> {row, col} end)
            cm_tuples = Enum.map(cm, fn %Move{to: {row, col}} -> {row, col} end)

            special_tuples =
              (pm ++ cm)
              |> Enum.filter(fn move -> !!move.castle or !!move.promotion end)
              |> Enum.map(fn %Move{to: {row, col}} -> {row, col} end)

            {pm_tuples, cm_tuples, special_tuples}
          end)

        {:noreply,
         assign(socket,
           clicked_square: {row, column},
           possible_moves: possible_moves,
           capture_moves: capture_moves,
           special_moves: special_moves
         )}

      from ->
        case Game.move(game, %Move{from: from, to: {row, column}}) do
          %Game{} = updated_game ->
            {:noreply,
             assign(socket,
               game: updated_game,
               clicked_square: {nil, nil},
               possible_moves: [],
               capture_moves: [],
               special_moves: []
             )}

          {:promotion_pending, move} ->
            {:noreply,
             assign(socket,
               pending_promotion: move,
               clicked_square: {nil, nil}
             )}

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

        {:noreply,
         assign(socket,
           game: updated_game,
           pending_promotion: nil,
           possible_moves: [],
           capture_moves: [],
           special_moves: []
         )}

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
