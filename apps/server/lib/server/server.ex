defmodule Server do
    def dns do
        Application.fetch_env!(:server, :dns)
    end

    def tolerance do
        Application.fetch_env!(:server, :tolerance)
    end
end