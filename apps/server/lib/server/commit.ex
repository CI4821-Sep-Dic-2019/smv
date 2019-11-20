defmodule Server.Commit do
    @moduledoc """
    Module for managing a dictionary of {filename, timestamp} -> nodes.
    """
    use Agent, restart: :permanent

    defstruct filename: "", timestamp: :os.system_time(:millisecond), message: ""

    @doc """
    Starts a new agent with two maps: ({filename, timestamp} -> [node]) and ({filename, timestamp} -> message)
    """
    def start_link(_opts \\ []) do
        Agent.start_link(fn -> {%{}, %{}} end)
    end

    @doc """
    Gets a list of nodes of `{filename, timestamp}`.
    """
    def get_nodes(dict, {filename, timestamp}) 
    when is_integer(timestamp) and is_binary(filename) do
        Agent.get(dict, &Map.get(elem(&1, 0), {filename, timestamp}))
    end

    @doc """
    Gets message of commit with `{filename, timestamp}`.
    """
    def get_message(dict, {filename, timestamp})
    when is_integer(timestamp) and is_binary(filename) do
        Agent.get(dict, &Map.get(elem(&1, 1), {filename, timestamp}))
    end

    @doc """
    Add `machine` as a node where commit is stored and its `message`.
    """
    def add(dict, %Server.Commit{filename: filename, timestamp: timestamp, message: message}, machine) 
    when is_atom(machine) and is_integer(timestamp) and is_binary(filename) and is_binary(message) do

        Agent.update(dict, fn {nodes_map, msg_map} -> 
            {
                Map.update(nodes_map, {filename, timestamp}, [machine], &[machine | &1]),
                Map.put(msg_map, {filename, timestamp}, message)
            }
        end)

    end

    @doc """
    Gets nodes where latest commit for `filename` is stored.
    """
    def get_latest_nodes(dict, filename) do
        Agent.get(dict, fn {map, _} ->
            Stream.filter(map, fn {{name, _}, _} -> name == filename end )
            |> Enum.reduce({{:error, -1}, []}, &compare_commits(&1, &2))
        end)
        |> elem(1)
    end

    @doc """
    Gets latest commit for `filename`
    """
    # TODO: Optimizar la obtención del timestamp mayor y evitar el reduce O(n). Quizás agregando otro mapa filename -> timestamp
    def get_latest_commit(dict, filename) do
        {{filename, timestamp}, message} = Agent.get(dict, fn {_, map} ->
            Stream.filter(map, fn {{name, _}, _} -> name == filename end )
            |> Enum.reduce({{:error, -1}, []}, &compare_commits(&1, &2) )
        end)
        %Server.Commit {
            filename: filename,
            timestamp: timestamp,
            message: message
        }
    end

    #TODO: Obtener commits ordenados por timestamp
    def get_commits(dict, filename) do
        nil
    end

    defp compare_commits({{_, c1}, _} = x, {{_, c2}, _} = y) do
        if (c1 <= c2), do: y, else: x 
    end

end