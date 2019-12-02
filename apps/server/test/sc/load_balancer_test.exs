defmodule ServerTest.LoadBalancer do
    use ExUnit.Case, async: true

    setup_all do
        Enum.each(Application.fetch_env!(:server, :node_list), fn node ->
            Server.Acuerdo.add_node(node)
        end)
        %{balancer: start_supervised!(SC.LoadBalancer)}
    end

    test "get consecutive `n` servers", %{balancer: balancer} do
        machine_name = System.get_env("MACHINE", "machine-name") 
        assert SC.LoadBalancer.next_servers(balancer, 1) == [:"foo@#{machine_name}"]
        assert SC.LoadBalancer.next_servers(balancer, 4) == [:"bar@#{machine_name}", :"goku@#{machine_name}", :"wayne@#{machine_name}", :"foo@#{machine_name}"]
        assert SC.LoadBalancer.next_servers(balancer, 2) == [:"bar@#{machine_name}", :"goku@#{machine_name}"]
        assert SC.LoadBalancer.next_servers(balancer, 7) == [:"wayne@#{machine_name}", :"foo@#{machine_name}", :"bar@#{machine_name}", :"goku@#{machine_name}", :"wayne@#{machine_name}", :"foo@#{machine_name}", :"bar@#{machine_name}"]
    end
end