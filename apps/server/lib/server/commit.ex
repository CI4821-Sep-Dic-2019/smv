defmodule Server.Commit do
    @moduledoc """
    Module for managing a dictionary of {filename, timestamp} -> nodes.
    """
    use Agent, restart: :permanent

    defstruct filename: "", timestamp: :os.system_time(:millisecond), message: ""

    @doc """
    Starts a new agent with two maps: ({filename, timestamp} -> [node]) and (filename ->  [{timestamp,message}])
    """
    def start_link(_opts \\ []) do
        Agent.start_link(fn -> {%{}, %{}} end)
    end

    @doc """
    Gets a list of nodes of `{filename, timestamp}`.
    """
    def get_nodes(commits, filename, timestamp)
    when is_integer(timestamp) and is_binary(filename) do
        Agent.get(commits, &Map.get(elem(&1, 0), {filename, timestamp}))
    end

    @doc """
    Gets timestamps and messages of commits with `filename`.
    """
    def get_filename_commits(commits, filename)
    when is_binary(filename) do
        Agent.get(commits, &Map.get(elem(&1, 1), filename))
    end

    @doc """
    Add `machine` as a node where commit is stored and its `message`.
    """
    def add_machine(commits, %Server.Commit{filename: filename, timestamp: timestamp, message: message}, machine)
    when is_atom(machine) and is_integer(timestamp) and is_binary(filename) and is_binary(message) do
        Agent.update(commits, fn {nodes_map, commits_msg} ->
            {
                Map.update(nodes_map, {filename, timestamp}, [machine], &[machine | &1]),
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
    Add several machines where commit is stored and its `message`.
    """
    def add_machines(commits, %Server.Commit{filename: filename, timestamp: timestamp, message: message}, machines)
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
        commit = get_latest_commit(commits, filename)
        get_nodes(commits, commit.filename, commit.timestamp)
    end

    @doc """
    Gets latest commit for `filename`
    """
    def get_latest_commit(commits, filename)
    when is_binary(filename) do
        case get_filename_commits(commits, filename) do
            [{timestamp, message} | _ ] -> %Server.Commit {
                filename: filename,
                timestamp: timestamp,
                message: message
            }
            [] -> %Server.Commit {
                filename: filename,
                timestamp: -1,
                message: :error
            }
        end
    end

    @doc """
    Gets latest `n` commits for `filename`
    """
    def get_latest_commits(commits, filename, n)
    when is_binary(filename) and is_integer(n) do
        commits_inf = Enum.take(get_filename_commits(commits, filename), n)
        Enum.map(commits_inf, fn {timestamp, message} ->
                %Server.Commit{
                filename: filename,
                timestamp: timestamp,
                message: message
            } end
        )
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
