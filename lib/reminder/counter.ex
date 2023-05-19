defmodule Counter do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    Process.send_after(self(), {:inc, 2}, 1000)
    {:ok, 0}
  end

  @impl true
  def handle_info({:inc, n}, state) do
    Process.send_after(self(), {:inc, n}, 1000)
    IO.puts("State: #{state}")
    {:noreply, state + n}
  end
end
