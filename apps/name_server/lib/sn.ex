defmodule SN do
    @moduledoc """
    Name Server or "Servidor de Nombre".
    """
    use Agent, restart: :permanent

    #TO DO: ampliar la estructura para la direccion en caso
    # que se necesiten dos argumentos
    def start_link(_opts \\ []) do
        Agent.start_link(fn -> :ok end)
    end

    def set_address(central_server, address) do
        Agent.update(central_server, fn _ -> address end)
    end

    def get_address(central_server) do
        Agent.get(central_server, &(&1))
    end

    def hello do
        :world
    end
end
