defmodule ServerTest.SC do
    use ExUnit.Case

    setup_all do
        assert Server.init()
    end

    setup do
        File.rm_rf "files"
        File.rm_rf "../../../../files"
        File.mkdir "files"
        File.mkdir "../../../../files"
    end

    @tag :distributed
    test "commit and replicate" do

        # FIRST COMMIT
        filename1 = "file.test"
        message1 = "SC Integration test"
        content1 = """
        -- This is a linked list in Vibrato Language, by David & Gus.
        chord List {
            next: Sample<List>
        }        
        """

        assert SC.commit(filename1, message1, content1) == :ok
        
        {commit1, servers1} = SC.update(filename1)
        # Check commit has correct info
        assert commit1.filename == filename1
        assert commit1.message == message1

        # Check servers are correct
        assert length(servers1) == Server.tolerance + 1

        # Check file is in each server
        Enum.each(servers1, fn server ->
            task = Task.Supervisor.async({Server.CoordTasks, server}, SA, :get_file, [commit1])
            assert Task.await(task) == {:ok, content1}
        end)


        # SECOND COMMIT
        message2 = "Add value to struct"
        content2 = """
        -- This is a linked list in Vibrato Language, by David & Gus.
        chord List {
            next: Sample<List>,
            value: quarter
        }        
        """

        assert SC.commit(filename1, message2, content2) == :ok

        {commit2, servers2} = SC.update(filename1)
        assert commit2.filename == filename1
        assert commit2.message == message2
        assert commit2.timestamp > commit1.timestamp

        assert length(servers2) == Server.tolerance + 1
        assert servers1 != servers2

        assert SC.log(filename1, 2) == {:ok, [commit2, commit1]}

        Enum.each(servers2, fn server ->
            task = Task.Supervisor.async({Server.CoordTasks, server}, SA, :get_file, [commit2])
            assert Task.await(task) == {:ok, content2}
        end)
    end

    @tag :distributed
    test "commits with different filenames" do
        # FIRST COMMIT
        filename1 = "file.test"
        message1 = "SC Integration test"
        content1 = "hola"

        # SECOND COMMIT
        filename2 = "lib.test"
        message2 = "A library"
        content2 = "¿cómo?"

        assert SC.commit(filename1, message1, content1) == :ok
        assert SC.commit(filename2, message2, content2) == :ok

        [{commit1, servers1}, {commit2, servers2}] = [SC.update(filename1), SC.update(filename2)]

        assert commit1.filename == filename1
        assert commit1.message == message1
        assert commit2.filename == filename2
        assert commit2.message == message2

        # For each server, check it has the correct file.
        Enum.each([{commit1, servers1, content1}, {commit2, servers2, content2}], fn {commit, servers, content} ->
            Enum.each(servers, fn server ->
                task = Task.Supervisor.async({Server.CoordTasks, server}, SA, :get_file, [commit])
                assert Task.await(task) == {:ok, content}
            end)
        end)
    end

    @tag :distributed
    test "update unknown filename" do
        assert SC.update("unknown.test") == {:error, :not_found}
        assert SC.checkout("unknown.test", 123) == {:error, :not_found}
    end

    @tag :distributed
    test "a down server is removed from list" do
        {nodes, _} = nodes_state = Server.Nodes.get_state()
        assert length(elem(nodes_state, 0)) > 0
        assert elem(nodes_state, 1) != nil

        # Choose a different node to simulate its crash
        crashed_node = Enum.filter(nodes, & &1 != Node.self())
            |> Enum.at(0)
        # Notify each node
        notify_crash(nodes, crashed_node)

        # Assert crashed node is not in the list
        {nodes1, _} = Server.Nodes.get_state()
        assert length(nodes1) == length(nodes) - 1
        assert Enum.find(nodes1, & &1 == crashed_node) == nil

        ## Test basic functionality
        filename1 = "file.test"
        message1 = "SC Integration test"
        content1 = "Yo x Ti, Tu x Mi"

        assert SC.commit(filename1, message1, content1) == :ok
        
        {commit1, servers1} = SC.update(filename1)
        # Check commit has correct info
        assert commit1.filename == filename1
        assert commit1.message == message1
         # Check servers are correct
         assert length(servers1) == Server.tolerance + 1

        # Restart crashed node
        restart_node(crashed_node)

        # Check node is again in list
        {nodes2, _} = Server.Nodes.get_state()
        assert length(nodes2) == length(nodes) 
        assert Enum.find(nodes2, & &1 == crashed_node) != nil
    end

    @tag :distributed
    test "crashed coordinator" do
        {nodes, crashed_node} = nodes_state = Server.Nodes.get_state()
        assert length(elem(nodes_state, 0)) > 0
        assert elem(nodes_state, 1) != nil

        # Notify each node
        notify_crash(nodes, crashed_node)

        # Assert crashed node is not in the list
        {nodes1, _} = Server.Nodes.get_state()
        assert length(nodes1) == length(nodes) - 1
        assert Enum.find(nodes1, & &1 == crashed_node) == nil

        coord1 = Task.Supervisor.async(
            {SN.TaskSupervisor, Server.dns()},
            SN,
            :get_address,
            []
        ) |> Task.await()
        assert coord1 != crashed_node

        ## Test basic functionality
        filename1 = "file.test"
        message1 = "SC Integration test"
        content1 = "Yo x Ti, Tu x Mi"

        assert SC.commit(filename1, message1, content1) == :ok
        
        {commit1, servers1} = SC.update(filename1)
        # Check commit has correct info
        assert commit1.filename == filename1
        assert commit1.message == message1
        # Check servers are correct
        assert length(servers1) == Server.tolerance + 1

        # Restart crashed node
        restart_node(crashed_node)
    end

    defp notify_crash(nodes, crashed_node) do
        Enum.filter(nodes, & &1 != crashed_node)
        |> Enum.map(&Task.Supervisor.async(
            {Server.CoordTasks, &1},
            Kernel,
            :send,
            [Server.Nodes, {:nodedown, crashed_node}]
        )) |> Enum.each(&Task.await/1)
    end

    defp restart_node(machine) do
        Task.Supervisor.async(
            {Server.CoordTasks, machine},
            Server,
            :init,
            [])
        |> Task.await()
    end
end