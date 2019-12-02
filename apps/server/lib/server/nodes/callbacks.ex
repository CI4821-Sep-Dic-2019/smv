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
    def handle_info({:nodedown, node}, {nodes, central_server}) do
        {:noreply, {
            List.delete(nodes, node),
            central_server
        }}
    end

    @doc """
    Add a node to the list of available distributed nodes.
    """
    @impl true
    def handle_call({:add_node, machine}, _from, {nodes, central_server} = state)
    when is_atom(machine) do
        if Enum.find(nodes, & &1 == machine) == nil do
            Node.monitor(machine, true)
            {:reply, :ok, {
                [machine | nodes],
                central_server
            }}
        else
            {:reply, :ok, state}
        end
    end

    @impl true
    def handle_call(:get_nodes, _from, state) do
        {:reply, elem(state, 0), state}
    end

    @impl true
    def handle_call({:set_coordinator, coordinator}, _from, state) do
        {servers, _} = state
        {:reply, :ok, {servers, coordinator}}
    end

    @impl true
    def handle_call(:get_coordinator, _from, state) do
        {:reply, elem(state, 1), state}
    end
end