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
    def put_file(commit, content) do
        {:ok, file} = File.open("#{path()}#{get_name(commit)}", [:write])
        IO.binwrite(file, content)
        File.close(file)
    end

    def get_name(%Server.Commit{filename: filename, timestamp: timestamp, message: _}) do
        "#{filename}-#{timestamp}"
    end

    defp path() do
        "../../files/"
    end
end
