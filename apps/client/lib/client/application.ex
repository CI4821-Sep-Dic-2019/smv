defmodule Client.Application do
    # See https://hexdocs.pm/elixir/Application.html
    # for more information on OTP Applications
    @moduledoc false

    use Application

    def start(_type, _args) do
        children = [
            {Task.Supervisor, name: Client.CoordTasks}
        ]

        # See https://hexdocs.pm/elixir/Supervisor.html
        # for other strategies and supported options
        opts = [strategy: :one_for_one, name: Client.Supervisor]
        Supervisor.start_link(children, opts)
    end
end
