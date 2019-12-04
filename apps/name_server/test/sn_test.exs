defmodule SNTest do
    use ExUnit.Case
    doctest SN

    setup do
        central_server = start_supervised!(SN)
        %{central_server: central_server}
    end

    test "greets the world" do
        assert SN.hello() == :world
    end

    test "Get central server", %{central_server: central_server} do
        assert SN.get_address(central_server) == nil
    end

    test "Set and Get central server", %{central_server: central_server} do
        address = :"m1@gus-Aspire-A515-51"
        SN.set_address(central_server, address)
        assert SN.get_address(central_server) == address
    end
end
