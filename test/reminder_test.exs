defmodule ReminderTest do
  use ExUnit.Case
  require Logger

  test "subscribing as a client" do
    Reminder.EventServer.subscribe()
  end

  test "adding an event" do
    Reminder.EventServer.add_event("test", "test", DateTime.utc_now())
  end

  # user assert

  test "events are properly stopped when a server is stopped (gracefully)" do
  end

  test "events are properly stopped when a server is stopped (abruptly)" do
  end

  test "events are properly cancelled" do
  end

  test "that when event elapsed, a client if notified" do
  end

  test "that event is stopped, when its time elapsed" do
  end

  test "that clients only get notifications for their events" do
  end
end
