defmodule Reminder.EventServer do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def stop() do
    GenServer.stop(__MODULE__)
  end

  def subscribe() do
    GenServer.cast(__MODULE__, {:subscribe, self()})
  end

  def add_event(name, date_time) do
    GenServer.call(__MODULE__, {:add_event, self(), name, date_time})
  end

  def cancel(name) do
    GenServer.call(__MODULE__, {:cancel, name})
  end

  @impl true
  def init(_) do
    Process.flag(:trap_exit, true)

    {:ok, %{events: %{}, clients: []}}
  end

  @impl true
  def handle_cast({:subscribe, pid}, state) do
    {:noreply, Map.put(state, :clients, [pid | state.clients])}
  end

  @impl true
  def handle_call({:add_event, client_pid, name, date_time}, _from, state) do
    try do
      pid = Reminder.Event.start_link(name, date_time)

      events = Map.put(state.events, name, %{name: name, pid: pid,
        date_time: date_time, client_pid: client_pid})

      {:reply, {:ok, pid}, %{state | events: events}}
    rescue
      error -> {:reply, {:error, error}, state}
    end
  end

  @impl true 
  def handle_call({:cancel, name}, _from, state) do
    {_, event} = Enum.find(state.events, fn {k, _} -> k == name end)
    :ok = Reminder.Event.cancel(event.pid)
    events = Map.delete(state.events, name)

    {:reply, :ok, %{state | events: events}}
  end

  @impl true
  def handle_info({:done, name}, state) do
    {_, event} = Enum.find(state.events, fn {k, _} -> k == name end)
    events = Map.delete(state.events, name)
    send(event.client_pid, {:done, name})
    Logger.info("Event done: #{name}")

    {:noreply, %{state | events: events}}
  end

  @impl true
  def handle_info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:EXIT, pid, _reason}, state) do
    {_, event} = Enum.find(state.events, fn {_, event} -> event.pid == pid end)
    events = Map.delete(state.events, event.name)
    {:noreply, %{state | events: events}}
  end

  @impl true
  def terminate(_reason, state) do
    Enum.each(state.events, fn {_, event} -> terminate_event(event.pid) end)
    :ok
  end

  defp terminate_event(pid) do
    if Process.alive?(pid) do
      case Reminder.Event.cancel(pid) do
        :error -> Logger.error("Couldn't stop the event process: #{inspect pid}")
        :ok -> :ok
      end
    end
  end
end
