defmodule Chess.GameServer do
  use GenServer
  alias Chess.Game

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via_tuple(game_id))
  end

  def join_game(game_id, player_id) do
    case GenServer.whereis(via_tuple(game_id)) do
      nil ->
        case DynamicSupervisor.start_child(Chess.GameSupervisor, {__MODULE__, game_id}) do
          {:ok, _pid} ->
            GenServer.call(via_tuple(game_id), {:join, player_id})

          {:error, {:already_started, _pid}} ->
            GenServer.call(via_tuple(game_id), {:join, player_id})
        end

      _pid ->
        GenServer.call(via_tuple(game_id), {:join, player_id})
    end
  end

  def make_move(game_id, player_id, move) do
    GenServer.call(via_tuple(game_id), {:move, player_id, move})
  end

  def get_game_state(game_id) do
    case GenServer.whereis(via_tuple(game_id)) do
      nil -> {:error, "Game not found"}
      _pid -> GenServer.call(via_tuple(game_id), :get_state)
    end
  end

  def possible_moves(game_id, from) do
    GenServer.call(via_tuple(game_id), {:possible_moves, from})
  end

  defp via_tuple(game_id) do
    {:via, Registry, {Chess.GameRegistry, game_id}}
  end

  # Server Callbacks
  @impl true
  def init(game_id) do
    initial_state = %{
      game_id: game_id,
      game: Game.new(),
      players: %{},
      white_player: nil,
      black_player: nil
    }

    {:ok, initial_state}
  end

  @impl true
  def handle_call({:join, player_id}, _from, state) do
    cond do
      state.white_player == nil ->
        new_state = %{
          state
          | white_player: player_id,
            players: Map.put(state.players, player_id, :white)
        }

        {:reply, {:ok, serialize_game_state(new_state)}, new_state}

      state.black_player == nil and state.white_player != player_id ->
        new_state = %{
          state
          | black_player: player_id,
            players: Map.put(state.players, player_id, :black)
        }

        broadcast_game_update(new_state)
        {:reply, {:ok, serialize_game_state(new_state)}, new_state}

      Map.has_key?(state.players, player_id) ->
        {:reply, {:ok, serialize_game_state(state)}, state}

      true ->
        {:reply, {:error, "Game is full"}, state}
    end
  end

  @impl true
  def handle_call({:move, player_id, move}, _from, state) do
    player_color = Map.get(state.players, player_id)

    cond do
      player_color == nil ->
        {:reply, {:error, "Player not in game"}, state}

      player_color != state.game.turn ->
        {:reply, {:error, "Not your turn"}, state}

      true ->
        case Game.move(state.game, move) do
          %Game{} = new_game ->
            new_state = %{state | game: new_game}
            broadcast_game_update(new_state)
            {:reply, {:ok, serialize_game_state(new_state)}, new_state}

          {:promotion_pending, pending_move} ->
            # Don't update game state yet, just return promotion pending
            {:reply, {:promotion_pending, pending_move}, state}

          {:error, reason} ->
            {:reply, {:error, reason}, state}

          _ ->
            {:reply, {:error, "Invalid move"}, state}
        end
    end
  end

  @impl true
  def handle_call({:possible_moves, {from_row, from_column}}, _from, state) do
    moves = Game.possible_moves(state.game, {from_row, from_column})
    {:reply, {:ok, moves}, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, serialize_game_state(state)}, state}
  end

  defp serialize_game_state(state) do
    %{
      game_id: state.game_id,
      game: state.game,
      white_player: state.white_player,
      black_player: state.black_player,
      game_status: get_game_status(state.game)
    }
  end

  defp get_game_status(game) do
    # You'll need to implement these functions in your Game module
    # or adapt this to your existing game state checking
    cond do
      Game.checkmate?(game) -> "checkmate"
      Game.check?(game) -> "check"
      Game.stalemate?(game) -> "stalemate"
      true -> "ongoing"
    end
  rescue
    # Fallback if these functions don't exist yet
    _ -> "ongoing"
  end

  defp broadcast_game_update(state) do
    Phoenix.PubSub.broadcast(
      Chess.PubSub,
      "game:#{state.game_id}",
      %{
        topic: "game:#{state.game_id}",
        event: "game_update",
        payload: serialize_game_state(state)
      }
    )
  end
end
