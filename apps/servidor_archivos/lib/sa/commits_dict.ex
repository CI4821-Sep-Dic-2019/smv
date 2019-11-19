defmodule SA.CommitsDict do
    @moduledoc """
    Module for managing a dictionary of {filename, commit} -> nodes.
    """
    use Agent, restart: :permanent

    @doc """
    Start dictionary agent.
    """
    def start_link(opts \\ []) do
        Agent.start_link(fn -> %{} end)
    end

    @doc """
    Get nodes of `{filename, commit}`.
    """
    def get(dict, {filename, commit}) when is_integer(commit) and is_binary(filename) do
        Agent.get(dict, &Map.get(&1, {filename, commit}))
    end

    @doc """
    Add `machine` to the list associated to `{filename, commit}`
    """
    def add(dict, {filename, commit}, machine) when is_atom(machine) and is_integer(commit) and is_binary(filename) do
        Agent.update(dict, fn map -> Map.update(map, {filename, commit}, [machine], &[machine | &1]) end)
    end

    @doc """
    Get nodes where latest commit for `filename` is stored.
    """
    def get_latest(dict, filename) do
        Agent.get(dict, fn map ->
            Stream.filter(map, fn {{name, _}, _} -> name == filename end )
            |> Enum.reduce({{:error, -1}, []}, &compare_commits(&1, &2) )
        end)
    end

    @doc """
    Return `x` if its commit is greater than `y`.
    """
    defp compare_commits({{_, c1}, _} = x, {{_, c2}, _} = y) do
        if (c1 <= c2), do: y, else: x
    end

    # TODO: map commit -> commit struct
end