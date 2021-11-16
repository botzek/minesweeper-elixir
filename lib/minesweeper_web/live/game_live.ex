defmodule MinesweeperWeb.GameLive do
  alias Minesweeper.Game
  use MinesweeperWeb, :live_view

  def mount(_params, _, socket) do
    socket = assign(socket, :game, Game.new("trivial"))
    socket = assign(socket, :game_difficulties, Game.difficulties())
    {:ok, socket, temporary_assigns: [game_difficulties: []]}
  end

  def handle_event("reveal", %{"row" => row_str, "col" => col_str}, socket) do
    position = {String.to_integer(row_str), String.to_integer(col_str)}
    game = Game.reveal(socket.assigns.game, position)
    socket = assign(socket, :game, game)
    {:noreply, socket}
  end

  def handle_event("toggle_flag", %{"row" => row_str, "col" => col_str}, socket) do
    position = {String.to_integer(row_str), String.to_integer(col_str)}
    game = Game.toggle_flag(socket.assigns.game, position)
    socket = assign(socket, :game, game)
    {:noreply, socket}
  end

  def handle_event("new_game", %{"difficulty" => difficulty}, socket) do
    socket = assign(socket, :game, Game.new(difficulty))
    {:noreply, socket}
  end
end
