defmodule SA do
    @moduledoc """
    Storage Server or "Servidor de Almacenamiento".
    """

    @doc """
    Gets the content of a file's commit.
    """
    def get_file(commit) do
        File.read("#{path()}#{get_name(commit)}")
    end

    @doc """
    Creates a file with name `filename`, `commit` and `content`.
    """
    def store(commit, content)
    when is_binary(content) do
        with {:ok, file} <- File.open("#{path()}#{get_name(commit)}", [:write]) do
            IO.binwrite(file, content)
            File.close(file)
        end
    end

    @doc """
    Remove file, maybe because a rollback.
    """
    def remove(filename, timestamp) do
        File.rm("#{path()}#{filename}-#{timestamp}")
    end

    @doc """
    Registry a new server store
    """
    def registry(tries \\ 3)
    when is_integer(tries) do
        central_server = get_central_server(dns())
        # To do
        # - Auto asignarse como SC cuando sea el primer servidor
        # - Verificar el orden en que se agregan los nodos a la lista
        #   o verficar que el orden no sea relevante
        # - Acomodar elecciones :(
        registry_inf = try_registry(central_server)
        if  registry_inf == :error do
            case tries do
                0 ->
                    IO.puts("No se pudo registrar el servidor")
                    Process.exit(self(), :kill)
                n -> registry(n-1)
            end
        else
            {nodes, commits_inf} = registry_inf
            Server.Commit.set_commits_inf(Server.Commit, commits_inf)
            Server.Nodes.set_coordinator(central_server)
            Enum.map(nodes, fn server -> Server.Nodes.add_node(server) end)
            Server.Nodes.add_node(Node.self())
        end
    end

    def get_name(%Server.Commit{filename: filename, timestamp: timestamp, message: _}) do
        "#{filename}-#{timestamp}"
    end

    defp try_registry(central_server) do
        try do
            Task.Supervisor.async(
                {SC.CoordTasks, central_server},
                SC,
                :registry_node,
                [Node.self()]
            ) |> Task.await()
        catch
            :exit, _ -> :error
        end
    end

    defp get_central_server(dns, tries \\ 3)
    when is_atom(dns) and is_integer(tries) do
        task = Task.Supervisor.async(
                {Client.CoordTasks, dns},
                SN,
                :get_address,
                []
            )
        central_server = Task.await(task)
        if Node.ping(central_server) == :pang do
            case tries do
                0 -> :noserver
                n ->
                    Process.sleep((4-n)*1000)
                    get_central_server(dns, n-1)
            end
        else
            central_server
        end
    end

    defp path() do
        "files/"
    end

    defp dns do :"dns@rubmary-Inspiron-7370" end
end
