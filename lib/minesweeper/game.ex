defmodule Minesweeper.Game do
  alias Minesweeper.Game

  defstruct board: %{}, rows: 0, cols: 0, mines: nil, mine_count: 0, status: :playing

  def new(rows, cols, mine_count) do
    %Game{
      board: create_board(rows, cols),
      rows: rows,
      cols: cols,
      mine_count: mine_count,
      status: :playing
    }
  end

  defp create_board(rows, cols) do
    for r <- 1..rows, c <- 1..cols, into: %{}, do: {{r, c}, :hidden}
  end

  def new(difficulty_id) do
    with {:ok, difficulty} <- difficulties() |> Enum.filter(fn s -> s.id == difficulty_id end) |> Enum.fetch(0)
    do
      new(difficulty.rows, difficulty.cols, difficulty.mine_count)
    else
      :error -> raise ArgumentError, message: "Unknown difficulty #{difficulty_id}"
    end
  end

  def difficulties() do
    [
      %{id: "trivial", name: "Trivial", rows: 9, cols: 9, mine_count: 5},
      %{id: "beginner", name: "Beginner", rows: 9, cols: 9, mine_count: 10},
      %{id: "intermediate", name: "Intermediate", rows: 16, cols: 16, mine_count: 40},
      %{id: "expert", name: "Expert", rows: 16, cols: 30, mine_count: 99}
    ]
  end

  def toggle_flag(game, position) do
    if game.status != :playing, do: raise ArgumentError, message: "Game status must be 'playing', not #{game.status}"

    state =
      case Map.get(game.board, position) do
        :flagged -> :hidden
        :hidden -> :flagged
      end

    %{game | board: Map.put(game.board, position, state)}
  end

  def reveal(game, position) do
    if game.status != :playing, do: raise ArgumentError, message: "Game status must be 'playing', not #{game.status}"

    game
    |> maybe_generate_mines(position)
    |> reveal_recurse(position)
    |> maybe_update_status()
  end

  defp maybe_generate_mines(game, position) do
    if game.mines do
      game
    else
      mines = game.board
      |> Map.keys()
      # don't let a mine be on the current or adjacent positions
      |> Enum.filter(fn other_position -> other_position != position and not is_position_adjacent?(position, other_position) end)
      |> Enum.shuffle()
      |> Enum.take(game.mine_count)
      |> MapSet.new()
      %{game | mines: mines}
    end
  end

  defp reveal_recurse(game, position) do
    state =
      if Set.member?(game.mines, position) do
        :exploded
      else
        adjacent_mine_count = game.mines
        |> Enum.filter(fn other_position -> is_position_adjacent?(position, other_position) end)
        |> Enum.count()
      end
    game = %{game | board: Map.put(game.board, position, state)}
    if 0 == state do
      reveal_adjacent_positions(game, position)
    else
      game
    end
  end

  defp maybe_update_status(game) do
    cond do
      Enum.any?(game.board, fn {_position, state} -> state == :exploded end) ->
        %{game | status: :lost}

      game.mine_count == Enum.count(game.board, fn {_position, state} -> state == :hidden or state == :flagged end) ->
        %{game | status: :won}

      true ->
        game
    end
  end

  defp is_position_adjacent?({my_row, my_col}, {other_row, other_col}) do
    row_difference = other_row - my_row
    col_difference = other_col - my_col

    row_difference >= -1 and row_difference <= 1
    and col_difference >= -1 and col_difference <= 1
    and (col_difference != 0 or row_difference != 0)
  end

  defp reveal_adjacent_positions(game, position) do
    Enum.reduce(adjacent_positions(game, position), game,
    fn adjacent_position, game_sofar ->
        if Map.get(game_sofar.board, adjacent_position) == :hidden do
        reveal_recurse(game_sofar, adjacent_position)
        else
        game_sofar
        end
    end)
  end

  defp adjacent_positions(game, position) do
    game.board
    |> Map.keys()
    |> Enum.filter(&(is_position_adjacent?(position, &1)))
  end
end
