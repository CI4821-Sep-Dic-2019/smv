defmodule ServerTest.Commit do
    use ExUnit.Case, async: true

    setup do
        dict = start_supervised!(Server.Commit)
        m1 = :foo@computer
        m2 = :bar@computer
        m3 = :baz@matrix
        %{dict: dict, machines: [m1, m2, m3]}
    end

    test "add and fetch commits' info", %{dict: dict, machines: [m1, m2, m3]} do
        commit = %Server.Commit{
            filename: "test_files/file.c", 
            timestamp: 124, 
            message: "test"
        }

        Server.Commit.add(dict, commit, m1)
        Server.Commit.add(dict, commit, m2)
        Server.Commit.add(dict, %{commit | :timestamp => 125}, m3)

        assert Server.Commit.get_nodes(dict, {commit.filename, commit.timestamp}) == [m2, m1]
        assert Server.Commit.get_latest_nodes(dict, commit.filename) == [m3]

        assert Server.Commit.get_message(dict, {commit.filename, commit.timestamp}) == commit.message

        assert Server.Commit.get_latest_commit(dict, commit.filename) == %{commit | :timestamp => 125}
    end
end