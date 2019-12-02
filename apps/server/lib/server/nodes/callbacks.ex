defmodule Server.Nodes.Callbacks do
    use GenServer, restart: :permanent
    import Server.Nodes
    
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

    @impl true
    def handle_call(:elections, _from, state) do
        answers = Enum.filter(get_nodes(), &(&1 > Node.self()))
            |> Enum.map(&call_elections(&1))

        unless Enum.any?(answers, &(check_ok(&1))) do
            set_coordinator()
            Enum.map(get_nodes(), &(notify_coordinator(&1, Node.self())))
                |> Enum.map(fn 
                    {:ok, task} -> Task.await(task)
                    _ -> :error
                end)
        end

        try do
            Enum.map(answers, fn
                {:ok, task} ->  Task.await(task)
                _ -> :error
            end)
        catch
            :exit, _ -> elections()
        end

        if Node.ping(get_coordinator()) == :pang do
            elections()
        end

        {:reply, :ok, state}
    end

    ###################### Private functions ###############################

    defp set_coordinator do
        task = Task.Supervisor.async(
            {SC.CoordTasks, dns()},
            SN,
            :set_address,
            [Node.self()]
        )
        Task.await(task)
    end

    defp call_elections(server) do
        try do
            {
                :ok,
                Task.Supervisor.async(
                    {SC.CoordTasks, server},
                    Server.Nodes,
                    :elections,
                    []
                )
            }
        catch
            :exit, _ -> :error
        end
    end

    defp notify_coordinator(server, coordinator) do
        try do
            {
                :ok,
                Task.Supervisor.async(
                    {SC.CoordTasks, server},
                    Server.Nodes,
                    :set_coordinator,
                    [coordinator]
                )
            }
        catch
            :exit, _ -> :error
        end
    end

    defp check_ok(answer) do
        case answer do
            {:ok, _task} -> true
            _ -> false
        end
    end

    defp dns do :"dns@rubmary-Inspiron-7370" end
end