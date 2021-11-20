defmodule MinesweeperWeb.CellComponent do
  use MinesweeperWeb, :live_component
  alias MinesweeperWeb.GamesInProgress

  def update(params, socket) do
    position = {params.row, params.col}
    socket = assign(socket, :position, position)
    socket = assign(socket, :row, params.row)
    socket = assign(socket, :col, params.col)
    socket = assign(socket, :game_id, params.game_id)

    game_id = params.game_id
    game = GamesInProgress.lookup(params.game_id)
    state = Map.get(game.board, position)
    socket = assign(socket, :state, state)

    state_glyph =
      case state do
        :hidden -> "&nbsp;"
        :flagged -> "&#x1f6a9;"
        :exploded -> "&#x1f4a5;"
        0 -> "&nbsp;"
        mines -> to_string(mines)
      end
    socket = assign(socket, :state_glyph, state_glyph)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class={"board-cell board-cell-state-#{@state}"}
         id={"cell-#{@row}-#{@col}"}
         phx-hook="ToggleFlag"
         phx-click="reveal"
         phx-value-row={@row}
         phx-value-col={@col}
         phx-value-state={@state}>
        <div class="board-cell-inner"><%= raw(@state_glyph) %></div>
    </div>
    """
  end
end
