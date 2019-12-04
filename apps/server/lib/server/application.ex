defmodule Server.Application do
  use Application

  def start(_type, _args) do
    ## Create supervisor tree
    children = [
      {Server.Nodes.Callbacks, name: Server.Nodes},
      {Server.Commit, name: Server.Commit},
      {SC.LoadBalancer, name: SC.LoadBalancer},
      {Task.Supervisor, name: Server.CoordTasks}
    ]

    opts = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, opts)

    # Server.init()
  end
end
