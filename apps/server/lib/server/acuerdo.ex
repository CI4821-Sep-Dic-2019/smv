defmodule Server.Acuerdo do

    use GenServer, restart: :permanent

    ###################### API ##############################

    @doc """
    Starts the genserver.
    """
    def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, :ok, opts)
    end

    def add_node(machine, servers \\ Servers) do
        GenServer.call(servers, {:add_node, machine})
    end

    def remove_node(machine, servers \\ Servers) do
        GenServer.call(servers, {:remove_node, machine})
    end
    
    def get_nodes(servers \\ Servers) do
        GenServer.call(servers, :get_nodes)
    end

    def set_coordinator(coordinator, servers \\ Servers)
    when is_atom(coordinator) do
        GenServer.call(servers, {:set_coordinator, coordinator})
    end

    def get_coordinator(servers \\ Servers) do
        GenServer.call(servers, :get_coordinator)
    end

    def elections(servers \\ Servers) do
        GenServer.call(servers, :elections)
    end

    ###################### GenServer Callbacks ##############################

    @impl true
    def init(:ok) do
        {:ok, {[], nil, %{}}}
    end

    @doc """
    Add a node to the list of available distributed nodes.
    """
    @impl true
    def handle_call({:add_node, machine}, _from, state)
    when is_atom(machine) do
        {nodes, central_server, refs} = state
        {:reply, :ok, {
            [machine | nodes],
            central_server,
            refs
        }}
    end

    @impl true
    def handle_call({:remove_node, machine}, _from, state)
    when is_atom(machine) do
        {nodes, central_server, refs} = state
        {:reply, :ok, {
            List.delete(nodes, machine),
            central_server,
            refs
        }}
    end

    @impl true
    def handle_call(:get_nodes, _from, state) do
        {:reply, elem(state, 0), state}
    end

    @impl true
    def handle_call({:set_coordinator, coordinator}, _from, state) do
        {servers, _, refs} = state
        {:reply, :ok, {servers, coordinator, refs}}
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
                    Server.Acuerdo,
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
                    Server.Acuerdo,
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
