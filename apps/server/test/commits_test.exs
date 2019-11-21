defmodule ServerTest.Commit do
    use ExUnit.Case, async: true

    setup do
        commits = start_supervised!(Server.Commit)
        m1 = :foo@computer
        m2 = :bar@computer
        m3 = :baz@matrix
        %{commits: commits, machines: [m1, m2, m3]}
    end

    test "add and fetch commits' info", %{commits: commits, machines: [m1, m2, m3]} do
        commit = %Server.Commit{
            filename: "file 1",
            timestamp: 1,
            message: "test 1"
        }

        Server.Commit.add(commits, commit, m1)
        Server.Commit.add(commits, commit, m2)
        Server.Commit.add(commits, %{commit | :timestamp => 125}, m3)

        assert Server.Commit.get_nodes(commits, {commit.filename, commit.timestamp}) == [m2, m1]
        assert Server.Commit.get_latest_nodes(commits, commit.filename) == [m3]

        assert Server.Commit.get_message(commits, {commit.filename, commit.timestamp}) == commit.message

        assert Server.Commit.get_latest_commit(commits, commit.filename) == %{commit | :timestamp => 125}
    end
end
