defmodule SA do
    require Logger
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
        Logger.info "Storing #{get_name(commit)} in #{Node.self()}"
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

    def get_name(%Server.Commit{filename: filename, timestamp: timestamp, message: _}) do
        "#{filename}-#{timestamp}"
    end

    defp path() do
        File.mkdir "files/"
        "files/"
    end
end
