defmodule SN do
    @moduledoc """
    Name Server or "Servidor de Nombre".
    """
    use Agent, restart: :permanent
    require Logger

    #TO DO: ampliar la estructura para la direccion en caso
    # que se necesiten dos argumentos
    def start_link(opts \\ []) do
        Agent.start_link(fn -> nil end, opts)
    end

    def set_address(central_server, address) do
        Logger.info "Set address to #{address}"
        Agent.update(central_server, fn _ -> address end)
    end

    def get_address(central_server) do
        Agent.get(central_server, &(&1))
    end

    def get_address do
        get_address(ServerName)
    end

    def set_address(address) do
        set_address(ServerName, address)
    end

    def hello do
        :world
    end
end
