defmodule Reminder.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [Reminder.EventServer]
    opts = [strategy: :one_for_one, name: Reminder.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
