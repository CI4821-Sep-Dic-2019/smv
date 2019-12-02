defmodule SC do
    @moduledoc """
    Server module with funcionalities for storage and coordination.
    """
    
    @doc """
    Get latest `filename`'s `commit` and the list of `servers` with it.
    """
    def update(filename)
    when is_binary(filename) do
      with  {:ok, commit} <- Server.Commit.get_latest_commit(Server.Commit, filename),
            servers <- Server.Commit.get_nodes_latest_commits(Server.Commit, filename),
            do: {commit, servers}
    end
  
    @doc """
    Get list of nodes that have the commit with `filename` and `timestamp`.
    """
    def checkout(filename, timestamp)
    when is_binary(filename) and is_integer(timestamp) do
      Server.Commit.get_nodes(Server.Commit, filename, timestamp)
    end
  
    @doc """
    Choose the servers where the new version of `filename`, with `content`, is going to be stored.
    Once `K+1` servers have this new version, an `:ok` is sent to the client, otherwise
    a `{:error, reasons}` is sent to the client.
    """
    def commit(filename, message, content) do
        # Next `n` servers, according to the load balancer.
        servers = SC.LoadBalancer.next_servers(SC.LoadBalancer, Server.tolerance() + 1)

        # Commit to be added
        new_commit = %Server.Commit{
            filename: filename,
            timestamp: :os.system_time(),
            message: message
        }

        # Make an async task for storing the file on each one of the `servers`, and
        # filter all the failed ones.
        tasks = Enum.map(servers, fn server ->
            Task.Supervisor.async(
                {SC.CoordTasks, server}, 
                SA,
                :store,
                [new_commit, content])
        end)
        |> Enum.map(&Task.await/1)

        failed_tasks = Enum.filter(tasks, &failed_task?(&1))

        # If there is any failed task, remove the new created file from each server
        # and return to the client the reasons.
        # Otherwise, update each server with the new information about the commits.
        if length(failed_tasks) > 0 do
            Enum.map(servers, fn server ->
                Task.Supervisor.async(
                    {SC.CoordTasks, server},
                    SA,
                    :remove,
                    [new_commit.filename, new_commit.timestamp])
            end)
            |> Enum.each(&Task.await/1)

            # Return `{:error, reasons}`, where each reason is obtained from
            # each failed task.
            reasons = Enum.map(failed_tasks, fn {:error, reason} -> 
                reason 
            end) 
            |> Enum.uniq()

            {:error, reasons}
        else
            # Send info to each server
            Enum.map(Server.node_list, fn server ->
                Task.Supervisor.async(
                    {SC.CoordTasks, server},
                    Server.Commit,
                    :add_nodes,
                    [Server.Commit, new_commit, servers]
                )
            end)
            |> Enum.each(&Task.await/1)

            :ok
        end
    end

    @doc """
    Get last `n` commits.
    """
    def log(filename, n)
    when is_binary(filename) and is_integer(n) do
        Server.Commit.get_latest_commits(Server.Commit, filename, n)
    end

    defp failed_task?(:ok), do: false
    defp failed_task?({:ok, _}), do: false
    defp failed_task?({:error, _}), do: true

end
  