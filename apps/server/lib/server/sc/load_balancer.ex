defmodule SC.LoadBalancer do
    @moduledoc """
    Module with a circular list for load balancer.
    """
    use Agent, restart: :permanent

    def start_link(_opts \\ []) do
        Agent.start_link(fn -> 0 end)
    end

    def next_servers(balancer, k)
    when is_integer(k) and k > 0 do
        idx = Agent.get(balancer, & &1)
        n = length(Server.node_list())
        rounds = ceil(k/n)

        # Get `k` elements starting at `idx`.
        result = List.duplicate(Server.node_list(), rounds + 1)
            |> List.flatten()
            |> Enum.drop(idx)
            |> Enum.take(k)

        # Update `idx = (idx + k) mod n`.
        Agent.update(balancer, & rem(&1 + k, n))
        result
    end
end