defmodule Client do
    @moduledoc """
    Client application.
    """
    def log(filename, n)
    when is_binary(filename) and is_integer(n) do
        central_server = get_central_server(dns())
        task = Task.Supervisor.async(
            {Client.CoordTasks, central_server},
            SC,
            :log,
            [filename, n]
        )
        case Task.await(task) do
            {:error, _} -> IO.puts("El archivo solicitado no existe")
            {:ok, commits} -> print_commits(commits)
        end
    end

    def update(filename)
    when is_binary(filename) do
        central_server = get_central_server(dns())
        {commit, servers} = get_servers_commit_update(filename)
        {result, content} = case commit do
            :error ->
                IO.puts("El archivo solicitado no existe")
                {:error, nil}
            _ -> retrieve_content(servers, commit.filename, commit.timestamp)
        end
        unless result == :error do
            with {:ok, file} <- File.open(filename, [:write]) do
                IO.binwrite(file, content)
                File.close(file)
                IO.puts("Update exitoso")
            end
        end
    end

    def checkout(filename, timestamp)
    when is_binary(filename) and is_integer(timestamp) do
        servers = get_servers_checkout(filename, timestamp)
        {result, content} = case servers do
            {:error, _ } ->
                IO.puts("La version solicitada no existe")
                {:error, nil}
            servers -> retrieve_content(servers, filename, timestamp)
        end
        unless result == :error do
            with {:ok, file} <- File.open(filename, [:write]) do
                IO.binwrite(file, content)
                File.close(file)
                IO.puts("Checkout exitoso")
            end
        end
    end

    defp retrieve_content(servers, filename, timestamp)
    when is_binary(filename) and is_integer(timestamp) do
        case servers do
            [] ->
                IO.puts("Error, intente nuevamente")
                {:error, nil}
            [server | tail] ->
                {result, content} = try_retrieve(server, filename, timestamp)
                if result == :error do
                    retrieve_content(tail, filename, timestamp)
                else
                    {:ok, content}
                end
        end
    end

    defp try_retrieve(server, filename, timestamp)
    when is_binary(filename) and is_integer(timestamp) do
        try do
            task = Task.Supervisor.async(
                {Client.CoordTasks, server},
                SA,
                :get_file,
                [%Server.Commit{filename: filename, timestamp: timestamp, message: ""}]
            )
            Task.await(task)
        catch
            :exit, _ -> {:error, nil}
        end
    end

    defp get_servers_checkout(filename, timestamp)
    when is_binary(filename) and is_integer(timestamp) do
        central_server = get_central_server(dns())
        task = Task.Supervisor.async(
            {Client.CoordTasks, central_server},
            SC,
            :checkout,
            [filename, timestamp]
        )
        Task.await(task)
    end

    defp get_servers_commit_update(filename)
    when is_binary(filename) do
        central_server = get_central_server(dns())
        task = Task.Supervisor.async(
            {Client.CoordTasks, central_server},
            SC,
            :update,
            [filename]
        )
        Task.await(task)
    end

    defp get_central_server(dns)
    when is_atom(dns) do
        {:ok, server} = File.read(path_file())
        central_server = String.to_atom(server)
        if test_comunication(central_server) == :error do
            task = Task.Supervisor.async(
                {Client.CoordTasks, dns},
                SN,
                :get_address,
                []
            )
            central_server = Task.await(task)
            with {:ok, file} <- File.open(path_file(), [:write]) do
                IO.write(file, ":\"#{central_server}\"")
                File.close(file)
            end
            central_server
        end
    end

    defp test_comunication(central_server)
    when is_atom(central_server) do
        try do
            task = Task.Supervisor.async(
                {Client.CoordTasks, central_server},
                SC,
                :test_comunication,
                []
            )
            Task.await(task)
        catch
            :exit, _ -> :error
        end
    end

    defp path_file do 'apps/client/server.txt' end

    defp dns do :"dns@rubmary-Inspiron-7370" end

    defp print_commits(commits) do
        Enum.map(
            Enum.reverse(commits),
            fn %Server.Commit{
                filename: _,
                timestamp: timestamp,
                message: message
            } -> IO.puts("#{timestamp}\t#{message}") end
        )
    end
end
