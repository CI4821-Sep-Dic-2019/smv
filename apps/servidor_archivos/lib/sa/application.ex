defmodule SA.Application do
  use Application

  def start(_type, _args) do
    children = [
      {SA.CommitsDict, name: SMV.CommitsDict}
    ]

    opts = [strategy: :one_for_one, name: SA.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
