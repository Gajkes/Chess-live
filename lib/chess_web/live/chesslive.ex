defmodule ChessWeb.Chesslive do
  alias Chess.Move
  use ChessWeb, :live_view
  alias Chess.Square
  alias Chess.GameServer

  def mount(%{"game_id" => game_id}, session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Chess.PubSub, "game:#{game_id}")
    end

    player_id = session["player_id"]

    case GameServer.join_game(game_id, player_id) do
      {:ok, game_state} ->
        socket =
          socket
          |> assign(%{
            game_id: game_id,
            player_id: player_id,
            game: game_state.game,
            player_color: get_player_color(player_id, game_state),
            white_player: game_state.white_player,
            black_player: game_state.black_player,
            game_status: game_state.game_status,
            waiting_for_opponent: game_state.black_player == nil,
            clicked_square: {nil, nil},
            pending_promotion: nil,
            possible_moves: [],
            capture_moves: [],
            special_moves: []
          })

        {:ok, socket}

      {:error, reason} ->
        {:ok, put_flash(socket, :error, "Failed to join game: #{reason}")}
    end
  end

  def mount(_params, _session, socket) do
    game_id = generate_game_id()
    {:ok, push_navigate(socket, to: "/game/#{game_id}")}
  end

  def render(
        # %{
        #   possible_moves: possible_moves,
        #   capture_moves: capture_moves,
        #   special_moves: special_moves
        # } =
        assigns
      ) do
    IO.inspect(assigns.player_id, label: "Assings look like thios:")

    ~H"""
    <div class="flex flex-col items-center space-y-6 mt-10">
      <!-- Game Info Panel -->
      <div class="bg-white p-4 rounded-lg shadow-md border">
        <div class="text-center space-y-2">
          <h1 class="text-xl font-bold">Chess Game: <%= @game_id %></h1>
          <div class="flex justify-center gap-4 text-sm">
            <span class="px-2 py-1 bg-gray-100 rounded">
              You: <%= if @player_color,
                do: String.capitalize(to_string(@player_color)),
                else: "Observer" %>
            </span>
            <span class="px-2 py-1 bg-gray-100 rounded">
              Turn: <%= String.capitalize(to_string(@game.turn)) %>
            </span>
          </div>

          <%= if @waiting_for_opponent do %>
            <div class="text-orange-600 font-semibold">
              Waiting for opponent to join...
            </div>
            <div class="text-xs text-gray-600">
              Share this URL: <%= url(ChessWeb.Endpoint, ~p"/game/#{@game_id}") %>
            </div>
          <% end %>

          <%= if @game_status != "ongoing" do %>
            <div class="text-red-600 font-bold text-lg">
              Game Over: <%= String.capitalize(@game_status) %>
            </div>
          <% end %>
        </div>
      </div>

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
  attr(:can_interact, :boolean, default: true)

  def square(assigns) do
    color =
      if rem(assigns.row_index + assigns.col_index, 2) == 0,
        do: "bg-[#a9745d]",
        else: "bg-white"

    # Blue outline if selected
    selected =
      assigns.clicked_square == {assigns.row_index, assigns.col_index} &&
        "outline outline-2 outline-blue-500 outline-offset-[-4px]"

    opacity = if assigns.can_interact, do: "", else: "opacity-60"

    assigns = assign(assigns, :color, color)
    assigns = assign(assigns, :selected, selected)
    assigns = assign(assigns, :opacity, opacity)

    ~H"""
    <div
      class={[
        "square relative w-[65px] h-[65px] flex items-center justify-center",
        @color,
        @selected,
        @opacity,
        (@can_interact && "cursor-pointer") || "cursor-not-allowed"
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
    if can_player_interact?(
         socket.assigns.player_color,
         socket.assigns.game.turn,
         socket.assigns.waiting_for_opponent
       ) do
      column = String.to_atom(col)
      row = String.to_integer(row)
      game = socket.assigns.game
      clicked = socket.assigns.clicked_square

      case clicked do
        {nil, nil} ->
          {possible_moves, capture_moves, special_moves} =
            GameServer.possible_moves(socket.assigns.game_id, {row, column})
            |> then(fn {_, {pm, cm}} ->
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
          case GameServer.make_move(socket.assigns.game_id, socket.assigns.player_id, %Move{
                 from: from,
                 to: {row, column}
               }) do
            {:ok, _} ->
              {:noreply,
               assign(socket,
                 clicked_square: {nil, nil},
                 possible_moves: [],
                 capture_moves: [],
                 special_moves: []
               )}

            {:promotion_pending, move} ->
              {:noreply, assign(socket, pending_promotion: move, clicked_square: {nil, nil})}

            {:error, reason} ->
              {:noreply, put_flash(socket, :error, reason)}
          end
      end
    else
      message =
        cond do
          socket.assigns.waiting_for_opponent ->
            "Waiting for opponent to join..."

          socket.assigns.player_color != socket.assigns.game.turn ->
            "It's not your turn!"

          true ->
            "You cannot make moves right now"
        end

      {:noreply, put_flash(socket, :info, message)}
    end
  end

  def handle_event("promote", %{"piece" => raw_piece}, socket) do
    move = socket.assigns.pending_promotion
    piece = String.to_existing_atom(raw_piece)
    promoted_move = %Move{move | promotion: piece}

    case GameServer.make_move(socket.assigns.game_id, socket.assigns.player_id, promoted_move) do
      {:ok, _game_state} ->
        {:noreply,
         assign(socket,
           pending_promotion: nil,
           possible_moves: [],
           capture_moves: [],
           special_moves: []
         )}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  def handle_info(
        %{topic: "game:" <> _game_id, event: "game_update", payload: game_state},
        socket
      ) do
    socket =
      socket
      |> assign(%{
        game: game_state.game,
        white_player: game_state.white_player,
        black_player: game_state.black_player,
        game_status: game_state.game_status,
        waiting_for_opponent: game_state.black_player == nil,
        clicked_square: {nil, nil},
        possible_moves: [],
        capture_moves: [],
        special_moves: []
      })
      |> clear_flash()

    {:noreply, socket}
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

  defp can_player_interact?(player_color, turn, waiting_for_opponent) do
    not waiting_for_opponent and player_color == turn
  end

  defp get_player_color(player_id, game_state) do
    cond do
      game_state.white_player == player_id -> :white
      game_state.black_player == player_id -> :black
      true -> nil
    end
  end

  defp generate_game_id do
    :crypto.strong_rand_bytes(6) |> Base.encode64() |> String.replace(~r/[^A-Za-z0-9]/, "")
  end
end
