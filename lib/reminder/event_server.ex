defmodule Reminder.EventServer do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def terminate() do
    GenServer.stop(__MODULE__)
  end

  def subscribe(client_pid) do
    GenServer.cast(__MODULE__, {:subscribe, client_pid})
  end

  def add_event(name, description, date_time) do
    GenServer.cast(__MODULE__, {:add_event, name, description, date_time})
  end

  def cancel(name) do
    GenServer.call(__MODULE__, {:cancel, name})
  end

  @impl true
  def init(_) do
    {:ok, %{events: %{}, clients: []}}
  end

  @impl true
  def handle_cast({:subscribe, pid}, state) do
    new_state = Map.put(state, :clients, [pid | state.clients])
    Logger.info("Current clients: #{inspect new_state}")
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:add_event, name, description, date_time}, state) do
    pid = Reminder.Event.start_link(name, date_time)
    events = Map.put(state.events, name, %{name: name, description:
      description, pid: pid, date_time: date_time})
    Logger.info("Current events: #{inspect events}")
    {:noreply, %{state | events: events}}
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

    Enum.each(state.clients, fn pid ->
      send(pid, {:done, name})
    end)

    {:noreply, %{state | events: events}}
  end

  @impl true
  def terminate(reason, state) do
    Enum.each(state.events, fn {_, event} ->
      case Reminder.Event.cancel(event.pid) do
        :error -> Logger.error("Couldn't stop the event process: #{inspect event.pid}")
        _ -> :ok
      end
    end)

    :ok
  end
end
