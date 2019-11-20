defmodule SA do
  @moduledoc """
  Storage Server or "Servidor de Almacenamiento".
  """

  @doc """
  Gets the content of a file's commit.
  """
  def get_file({filename, commit}) do
    File.read (get_name {filename, commit})
  end

  @doc """
  Creates a file with name `filename`, `commit` and `content`.
  """
  def put_file({filename, commit}, content) do
    {:ok, file} = File.open(get_name({filename, commit}), [:write])
    IO.binwrite(file, content)
    File.close(file)
  end

  def get_name({filename, commit}) do
    "#{filename}-#{inspect commit}"
  end

end
  