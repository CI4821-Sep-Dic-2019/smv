defmodule Server.Commit do
    @moduledoc """
    Module for managing a dictionary of {filename, timestamp} -> nodes.
    """
    use Agent, restart: :permanent

    defstruct filename: "", timestamp: :os.system_time(:millisecond), message: ""

    @doc """
    Starts a new agent with two maps: ({filename, timestamp} -> [node]) and (filename ->  [{timestamp,message}])
    """
    def start_link(opts \\ []) do
        Agent.start_link(fn -> {%{}, %{}} end, opts)
    end

    @doc """
    Get all state.
    """
    def get_state(commits \\ Server.Commit) do
        Agent.get(commits, & &1)
    end

    @doc """
    Set state.
    """
    def set_state(commits \\ Server.Commit, new_state) do
        Agent.update(commits, fn _ -> new_state end )
    end

    @doc """
    Gets a list of nodes of `{filename, timestamp}`.
    Returns `{:error, :not_found}` if there are not commits to this `filename`.
    """
    def get_nodes(commits, filename, timestamp)
    when is_integer(timestamp) and is_binary(filename) do
        Agent.get(
            commits, 
            &Map.get(elem(&1, 0), 
            {filename, timestamp}, 
            {:error, :not_found}))
    end

    @doc """
    Add `machine` as a node where commit is stored and its `message`.
    """
    def add_node(commits, %Server.Commit{filename: filename, timestamp: timestamp, message: message}, machine)
    when is_atom(machine) and is_integer(timestamp) and is_binary(filename) and is_binary(message) do
        Agent.update(commits, fn {nodes_map, commits_msg} ->
            {
                Map.update(nodes_map, {filename, timestamp}, [machine], fn machines ->
                    if machine in machines do machines else [machine | machines] end
                end ),
                Map.update(
                    commits_msg,
                    filename,
                    [{timestamp, message}],
                    &insert_timestamp_message(&1, timestamp, message)
                )
            }
        end )
    end

    @doc """
    Add several machines where commit is stored and its `message`.
    """
    def add_nodes(commits, %Server.Commit{filename: filename, timestamp: timestamp, message: message}, machines)
    when is_integer(timestamp) and is_binary(filename) and is_binary(message) do
        Agent.update(commits, fn {nodes_map, commits_msg} ->
            {
                Map.update(nodes_map, {filename, timestamp}, machines, fn list -> machines++list end),
                Map.update(
                    commits_msg,
                    filename,
                    [{timestamp, message}],
                    &insert_timestamp_message(&1, timestamp, message)
                )
            }
        end)
    end

    @doc """
    Gets nodes where latest commit for `filename` is stored.
    """
    def get_nodes_latest_commits(commits, filename)
    when is_binary(filename) do
        with    {:ok, commit} <- get_latest_commit(commits, filename),
                do: get_nodes(commits, commit.filename, commit.timestamp)
    end

    
    # Gets a stream of the commits of `filename`.
    defp get_commits_stream(commits, filename) do
        Agent.get(commits, &Map.get(elem(&1, 1), filename, []))
        |> Stream.map(fn {timestamp, message} -> %Server.Commit{
            filename: filename,
            timestamp: timestamp,
            message: message}
        end)
    end

    @doc """
    Gets timestamps and messages of commits with `filename`.

    Returns `{:error, :not_found}` if there are not commits to this `filename`,
    otherwise returns `{:ok, results}`.
    """
    def get_commits(commits, filename)
    when is_binary(filename) do
        results = get_commits_stream(commits, filename)
        |> Enum.to_list()
        case results do
            [] -> {:error, :not_found}
            _ -> {:ok, results}
        end
    end

    @doc """
    Gets latest commit for `filename`
    """
    def get_latest_commit(commits, filename)
    when is_binary(filename) do
        with {:ok, [commit | _]} <- get_latest_commits(commits, filename, 1) do
            {:ok, commit}
        end
    end

    @doc """
    Gets latest `n` commits for `filename`
    """
    def get_latest_commits(commits, filename, n)
    when is_binary(filename) and is_integer(n) do
        results = get_commits_stream(commits, filename)
        |> Enum.take(n)
        case results do
            [] -> {:error, :not_found}
            _ -> {:ok, results}
        end
    end

    defp insert_timestamp_message(list, timestamp, message) do
        case list do
            [] -> [{timestamp, message}]
            [{t0, m0} | tail] -> cond do
                t0 <  timestamp -> [{timestamp, message} | list]
                t0 >  timestamp -> [{t0, m0} | insert_timestamp_message(tail, timestamp, message)]
                t0 == timestamp -> list
            end
        end
    end
end
