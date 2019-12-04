defmodule Server do
    require Logger
    def dns do
        Application.fetch_env!(:server, :dns)
    end

    def tolerance do
        Application.fetch_env!(:server, :tolerance)
    end

    def init() do
        Logger.info "Trying to add #{Node.self()} to the system"
        ## Get central server
        central_server = Task.Supervisor.async(
            {SN.TaskSupervisor, Server.dns()},
            SN,
            :get_address,
            []
            ) |> Task.await()
        
        central_server = 
            unless central_server do
                Logger.warn "Central server not set in DNS"
                Server.Nodes.elections()
            else
                central_server
            end

        ## Register to the distributed system
        {nodes_state, commits_state} = Task.Supervisor.async(
            {Server.CoordTasks, central_server},
            SC,
            :register_node,
            [Node.self()]
        ) |> Task.await()

        ## Update state
        Server.Nodes.set_coordinator(elem(nodes_state, 1))
        Enum.each(elem(nodes_state, 0), & Server.Nodes.add_node(&1))
        Server.Commit.set_state(commits_state)
    end
end