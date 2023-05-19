alias Reminder.EventServer
alias Reminder.EventServer, as: ES
alias Reminder.Event

defmodule U do

  def add_seconds(n) do
    DateTime.add(DateTime.utc_now(), n, :second)
  end

  def await do
    receive do
      m -> m
    after
      5000 ->
        :timeout
    end
  end

  def find_server do
    Process.whereis(EventServer)
  end
end
