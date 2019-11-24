defmodule Server do
    def node_list do
        Application.fetch_env!(:server, :node_list)
    end

    def tolerance do
        Application.fetch_env!(:server, :tolerance)
    end
end