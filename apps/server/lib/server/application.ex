defmodule Server.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Server.Acuerdo, name: Servers},
      {Server.Commit, name: Server.Commit},
      {SC.LoadBalancer, name: SC.LoadBalancer},
      {Task.Supervisor, name: SC.CoordTasks}
    ]

    opts = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
