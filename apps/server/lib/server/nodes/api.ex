defmodule Server.Nodes do
    ###################### API ##############################

    def get_state(servers \\ Server.Nodes) do
        GenServer.call(servers, :get_state)
    end

    def set_state(new_state, servers \\ Server.Nodes) do
        GenServer.call(servers, {:set_state, new_state})
    end

    def add_node(machine, servers \\ Server.Nodes) do
        GenServer.call(servers, {:add_node, machine})
    end
    
    def get_nodes(servers \\ Server.Nodes) do
        GenServer.call(servers, :get_nodes)
    end

    def set_coordinator(coordinator, servers \\ Server.Nodes)
    when is_atom(coordinator) do
        GenServer.call(servers, {:set_coordinator, coordinator})
    end

    def get_coordinator(servers \\ Server.Nodes) do
        GenServer.call(servers, :get_coordinator)
    end

    def elections(servers \\ Server.Nodes) do
        GenServer.call(servers, :elections)
    end
end
