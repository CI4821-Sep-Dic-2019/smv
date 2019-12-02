defmodule Server.Nodes.Callbacks do
    use GenServer, restart: :permanent
    
    @doc """
    Starts the genserver.
    """
    def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, :ok, opts)
    end

    ###################### GenServer Callbacks ##############################

    @doc """
    State is:
    - List of nodes in the system.
    - Current coordinator.
    """
    @impl true
    def init(:ok) do
        {:ok, {[], nil}}
    end

    @doc """
    Handle a down server.
    """
    @impl true
    def handle_info({:nodedown, node}, {nodes, coordinator}) do
        if coordinator == node do
            Task.async(fn -> SA.Elections.elections() end)
        end
        {:noreply, {
            List.delete(nodes, node),
            coordinator
        }}
    end

    @impl true
    def handle_info(_inf, state) do
        {:noreply, state}
    end

    @doc """
    Add a node to the list of available distributed nodes.
    """
    @impl true
    def handle_call({:add_node, machine}, _from, {nodes, coordinator})
    when is_atom(machine) do
        if Enum.find(nodes, & &1 == machine) == nil do
            Node.monitor(machine, true)
            {:reply, :ok, {
                [machine | nodes],
                coordinator
            }}
        else
            {:reply, :ok, {nodes, coordinator}}
        end
    end

    @impl true
    def handle_call(:get_nodes, _from, {nodes, coordinator}) do
        {:reply, nodes, {nodes, coordinator}}
    end

    @impl true
    def handle_call({:set_coordinator, coordinator}, _from, {nodes, _coordinator}) do
        {:reply, :ok, {nodes, coordinator}}
    end

    @impl true
    def handle_call(:get_coordinator, _from, {nodes, coordinator}) do
        {:reply, coordinator, {nodes, coordinator}}
    end
end
