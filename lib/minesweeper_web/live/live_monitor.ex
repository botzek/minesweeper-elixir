defmodule MinesweeperWeb.LiveMonitor do
  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, %{views: %{}}}
  end

  def monitor(pid, module, data) do
    GenServer.call(__MODULE__, {:monitor, pid, module, data})
  end

  def update(pid, data) do
    GenServer.call(__MODULE__, {:update, pid, data})
  end

  def demonitor(pid) do
    GenServer.call(__MODULE__, {:demonitor, pid})
  end

  def handle_call({:monitor, pid, module, data}, _, state) do
    monitor_ref = Process.monitor(pid)
    {:reply, :ok, %{state | views: Map.put(state.views, pid, {monitor_ref, module, data})}}
  end

  def handle_call({:demonitor, pid}, _, state) do
    {{monitor_ref, _module, _data}, new_views} = Map.pop(state.views, pid)
    Process.demonitor(monitor_ref)
    {:reply, :ok, %{state | views: new_views}}
  end

  def handle_call({:update, pid, data}, _, state) do
    {monitor_ref, module, _data} = Map.get(state.views, pid)
    {:reply, :ok, %{state | views: Map.put(state.views, pid, {monitor_ref, module, data})}}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    {{_monitor_ref, module, data}, new_views} = Map.pop(state.views, pid)
    Task.start(fn ->
      try do
        module.unmount(reason, data)
      rescue
        e -> Logger.error("#{module}.unmount error: #{Exception.format(:error, e, __STACKTRACE__)}")
      end
    end)
    {:noreply, %{state | views: new_views}}
  end
end
