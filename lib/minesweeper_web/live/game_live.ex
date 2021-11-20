defmodule MinesweeperWeb.GameLive do
  use MinesweeperWeb, :live_view

  alias Minesweeper.Game
  alias MinesweeperWeb.{GamesInProgress, LiveMonitor}

  def mount(_params, _, socket) do
    game = Game.new("trivial")
    game_id = generate_game_id()

    GamesInProgress.insert(game_id, game)
    LiveMonitor.monitor(self(), MinesweeperWeb.GameLive, game_id)

    socket = assign(socket, :game, game)
    socket = assign(socket, :game_difficulties, Game.difficulties())
    socket = assign(socket, :game_id, game_id)
    {:ok, socket, temporary_assigns: [game_difficulties: []]}
  end

  def unmount(_reason, game_id) do
    GamesInProgress.delete(game_id)
  end

  def handle_event("reveal", %{"row" => row_str, "col" => col_str, "state" => state}, socket) when state == "hidden" do
    row = String.to_integer(row_str)
    col = String.to_integer(col_str)

    old_game = socket.assigns.game
    game = Game.reveal(socket.assigns.game, {row, col})
    socket = assign(socket, :game, game)

    GamesInProgress.insert(socket.assigns.game_id, game)

    game.board
    |> Map.keys()
    |> Enum.filter(&(Map.get(game.board, &1) != Map.get(old_game.board, &1)))
    |> Enum.each(&send_cell_update(socket.assigns.game_id, &1))
    {:noreply, socket}
  end

  def handle_event("reveal", %{"row" => _row_str, "col" => _col_str, "state" => _}, socket), do: {:noreply, socket}

  def handle_event("toggle_flag", %{"row" => row_str, "col" => col_str, "state" => state}, socket) when state == "hidden" or state == "flagged" do
    row = String.to_integer(row_str)
    col = String.to_integer(col_str)
    game = Game.toggle_flag(socket.assigns.game, {row, col})
    socket = assign(socket, :game, game)

    GamesInProgress.insert(socket.assigns.game_id, game)

    send_cell_update(socket.assigns.game_id, {row, col})
    {:noreply, socket}
  end

  def handle_event("toggle_flag", %{"row" => _row_str, "col" => _col_str, "state" => _}, socket), do: {:noreply, socket}

  def handle_event("new_game", %{"difficulty" => difficulty}, socket) do
    GamesInProgress.delete(socket.assigns.game_id)

    game = Game.new(difficulty)
    game_id = generate_game_id()

    LiveMonitor.update(self(), game_id)
    GamesInProgress.insert(game_id, game)

    socket = assign(socket, :game, game)
    socket = assign(socket, :game_id, game_id)
    {:noreply, socket}
  end

  defp generate_game_id(), do: Ecto.UUID.generate

  defp send_cell_update(game_id, {row, col}) do
    cell_id =  "#{game_id}-#{row}-#{col}"
    send_update(MinesweeperWeb.CellComponent, id: cell_id, row: row, col: col, game_id: game_id)
  end
end
