defmodule MinesweeperWeb.GamesInProgress do
  use GenServer

  @table_name __MODULE__

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    :ets.new(@table_name, [
          :public,
          :set,
          :named_table,
          {:read_concurrency, true},
          {:write_concurrency, true}])
    {:ok, []}
  end

  def insert(game_id, game) do
    :ets.insert(@table_name, {game_id, game})
  end

  def lookup(game_id) do
    case :ets.lookup(@table_name, game_id) do
      [] -> nil
      [{_game_id, game}] -> game
    end
  end

  def delete(game_id) do
    :ets.delete(@table_name, game_id)
  end
end
