defmodule Client do
    @moduledoc """
    Client application.
    """
    def log(filename, n) do
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
                filename: filename,
                timestamp: timestamp,
                message: message
            } -> IO.puts("#{timestamp}\t#{message}") end
        )
    end
end
