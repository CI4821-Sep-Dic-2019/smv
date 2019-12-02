defmodule SA.Elections do
	@moduledoc """
    Server module with funcionalities to elect a new coordinator
    """

    @doc """
    Call elections using bully algorithm
    """
    def elections() do
        answers = Enum.filter(Server.Nodes.get_nodes(), &(&1 > Node.self()))
            |> Enum.map(&call_elections(&1))

        unless Enum.any?(answers, &(check_ok(&1))) do
            set_coordinator()
            Enum.map(Server.Nodes.get_nodes(), &(notify_coordinator(&1, Node.self())))
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

        if Node.ping(Server.Nodes.get_coordinator()) == :pang do
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
                    SA.Elections,
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
