defmodule Client do
    @moduledoc """
    Client application.
    """

    def help do
        message =
        '''
        Sistema Manejador de Versiones SVM
        Uso: smv <comando> <argumentos>

        Estos son los comandos disponibles:
          help
        \t    Muestra los comandos disponibles
          log       <file name> <n>
        \t    Muestra la información de los últimos <n> commits del archivo cuyo
        \t    nombre sea <file name>
          update    <file name>
        \t    Proporciona la última versión del archivo <file name>
          checkout  <file name> <timestamp>
        \t    Proporciona la versión del archivo <file name> cuyo commit creada
        \t    en el tiempo <timestamp>
          commit    <path file> <file name> <message>
        \t    Guarda el archivo local que se encuentre en <path file> como una
        \t    nueva versión de <file name> con un mensaje <message>.
        '''
        IO.puts(message)
    end

    def log(filename, n)
    when is_binary(filename) and is_integer(n) do
        central_server = get_central_server(Server.dns())
        task = Task.Supervisor.async(
            {Server.CoordTasks, central_server},
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

    def commit(pathfile, filename, message)
    when is_binary(pathfile) and is_binary(filename) and is_binary(message) do
        {read_result, content} = File.read(pathfile)
        commit_result = case read_result do
            :error -> {:error, :incorrect_path}
            :ok -> try_commit(filename, message, content)
        end
        case commit_result do
            {:error, :incorrect_path} -> IO.puts("El path especificado es incorrecto")
            {:error, _reason} -> IO.puts("Error, intenta más tarde")
            :ok -> IO.puts("Commit exitoso")
        end
    end

    defp try_commit(filename, message, content)
    when is_binary(filename) and is_binary(message) and is_binary(content) do
        central_server = get_central_server(Server.dns())
        try do
            task = Task.Supervisor.async(
                {Server.CoordTasks, central_server},
                SC,
                :commit,
                [filename, message, content]
            )
            Task.await(task)
        catch
            :exit, _ -> {:error, :exception}
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
                {Server.CoordTasks, server},
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
        central_server = get_central_server(Server.dns())
        task = Task.Supervisor.async(
            {Server.CoordTasks, central_server},
            SC,
            :checkout,
            [filename, timestamp]
        )
        Task.await(task)
    end

    defp get_servers_commit_update(filename)
    when is_binary(filename) do
        central_server = get_central_server(Server.dns())
        task = Task.Supervisor.async(
            {Server.CoordTasks, central_server},
            SC,
            :update,
            [filename]
        )
        Task.await(task)
    end

    defp get_central_server(dns, tries \\ 3)
    when is_atom(dns) and is_integer(tries) do
        task = Task.Supervisor.async(
                {SN.TaskSupervisor, dns},
                SN,
                :get_address,
                []
            )
        central_server = Task.await(task)
        if Node.ping(central_server) == :pang do
            case tries do
                0 ->
                    IO.puts("No se pudo conectar con el servidor central")
                    Process.exit(self(), :kill)
                n ->
                    Process.sleep((4-n)*1000)
                    get_central_server(dns, n-1)
            end
        else
            central_server
        end
    end

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
