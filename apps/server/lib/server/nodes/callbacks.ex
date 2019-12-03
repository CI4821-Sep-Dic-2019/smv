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
        new_state = {
            List.delete(nodes, node),
            central_server
        }
        new_state = elections(new_state)
        {:noreply, new_state}
    end

    @impl true
    def handle_info(_, state) do
        {:noreply, state}
    end

    @doc """
    Get all state.
    """
    @impl true
    def handle_call(:get_state, _from, state) do
        {:reply, state, state}
    end

    @doc """
    Set new state
    """
    @impl true
    def handle_call({:set_state, new_state}, _from, _state) do
        {:reply, :ok, new_state}
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
        {:reply, get_nodes(state), state}
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
        {_, new_coordinator} = new_state = elections(state)
        {:reply, new_coordinator, new_state}
    end

    ###################### Private functions ###############################

    defp register_coordinator do
        Task.Supervisor.async(
            {SN.TaskSupervisor, Server.dns()},
            SN,
            :set_address,
            [Node.self()]
        )
        |> Task.await()
    end

    defp call_elections(server) do
        try do
            {
                :ok,
                Task.Supervisor.async(
                    {Server.CoordTasks, server},
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
                    {Server.CoordTasks, server},
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

    defp elections({nodes, _} = state) do
        answers = Enum.filter(get_nodes(state), &(&1 > Node.self()))
            |> Enum.map(&call_elections(&1))

        unless Enum.any?(answers, &(check_ok(&1))) do
            register_coordinator()

            Enum.filter(get_nodes(state), & &1 != Node.self())
            |> Enum.map( &notify_coordinator(&1, Node.self()) )
            |> Enum.map(fn 
                {:ok, task} -> Task.await(task)
                _ -> :error
            end)

            {nodes, Node.self()}
        else
            state
        end
    end

    defp get_nodes(state) do
        elem(state, 0)
    end

end