defmodule Server.Acuerdo do

    use Agent, restart: :permanent

    def start_link(opts \\ []) do
        Agent.start_link(fn -> {[], :ok} end, opts)
    end

    def add_node(machine, state \\ Servers)
    when is_atom(machine) do
        Agent.update(state, fn {nodes, central_server} ->
            {
                [machine | nodes],
                central_server
            }
        end )
    end

    def remove_node(machine, state \\ Servers)
    when is_atom(machine) do
        Agent.update(state, fn {nodes, central_server} ->
            {
                List.delete(nodes, machine),
                central_server
            }
        end)
    end

    def get_nodes(state \\ Servers) do
        Agent.get(state, fn {nodes, _} -> nodes end)
    end

    def set_coordinator(coordinator, state \\ Servers) do
        Agent.update(state, fn {servers, _} -> {servers, coordinator} end)
    end

    def get_coordinator(state \\ Servers) do
        Agent.get(state, fn {_, coordinator} -> coordinator end)
    end

    def elections do
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

        :ok
    end

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
