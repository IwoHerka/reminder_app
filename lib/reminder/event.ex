defmodule Reminder.Event do
  require Logger

  def start(event_name, date_time) do
    spawn(__MODULE__, :init, [self(), event_name, date_time])
  end

  def start_link(event_name, date_time) do
    spawn_link(__MODULE__, :init, [self(), event_name, date_time])
  end

  def cancel(pid) do
    send(pid, {self(), nil, :cancel})

    receive do
      {:ok, nil} -> :ok
    after
      5000 -> :error
    end
  end

  def init(event_server_pid, event_name, date_time) do
    time_left = get_time_left(date_time)
    Logger.info("Time left: #{inspect time_left}")
    loop(event_server_pid, event_name, time_left)
  end

  defp loop(event_server_pid, event_name, time_left) do
    receive do
      {^event_server_pid, ref, :cancel} ->
        send(event_server_pid, {:ok, ref})
    after
      time_left * 1000 ->
        send(event_server_pid, {:done, event_name})
    end
  end

  @doc """
  Calculate time difference between new and specified
  datetime in seconds.
  """
  defp get_time_left(date_time) do
    DateTime.diff(date_time, DateTime.utc_now(), :second)
  end
end
