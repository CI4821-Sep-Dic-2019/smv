defmodule ServerTest.Commit do
    use ExUnit.Case, async: true

    setup do
        commits = start_supervised!(Server.Commit)
        m1 = :foo@m1
        m2 = :bar@m2
        m3 = :baz@m3
        m4 = :rubmary@m4
        %{commits: commits, machines: [m1, m2, m3, m4]}
    end
    
    test "add and get one node", %{commits: commits, machines: [m1 | _]} do
        commit = %Server.Commit{
            filename: "file.test",
            timestamp: :os.system_time(),
            message: "test"
        }
        Server.Commit.add_node(commits, commit, m1)

        # Test `m1` is the one and only node.
        assert Server.Commit.get_nodes(commits, commit.filename, commit.timestamp) == [m1]

        # Test `commit` is the one and only commit.
        assert Server.Commit.get_commits(commits, commit.filename) == {:ok, [commit]}
    end

    test "Commit not found", %{commits: commits} do
        assert Server.Commit.get_nodes_latest_commits(commits, "abc.abc") == {:error, :not_found}
    end

    test "add many commits to the same file", %{commits: commits, machines: [m1 | _]} do
        [c1, c2, c3] = commit_list = [
            %Server.Commit{
                filename: "file1.test",
                timestamp: 0,
                message: "test one"
            },
            %Server.Commit{
                filename: "file1.test",
                timestamp: 2,
                message: "test two"
            },
            %Server.Commit{
                filename: "file1.test",
                timestamp: 1,
                message: "test three"
            }
        ]

        # Add each commit to `m1`.
        Enum.each(commit_list, &Server.Commit.add_node(commits, &1, m1))

        assert Server.Commit.get_latest_commit(commits, "file1.test") == {:ok, Enum.at(commit_list, 1)}
        assert Server.Commit.get_commits(commits, "file1.test") == {:ok, [c2, c3, c1]}
    end

    test "add same commit in different nodes", %{commits: commits, machines: machines} do
        commit = %Server.Commit{
            filename: "file.test",
            timestamp: :os.system_time(),
            message: "test"
        }
        Server.Commit.add_nodes(commits, commit, machines)

        assert Server.Commit.get_nodes_latest_commits(commits, "file.test") == machines
        assert Server.Commit.get_nodes(commits, "file.test", commit.timestamp) == machines
    end

    test "add many commits in different nodes", %{commits: commits, machines: machines} do
        [c1, c2, c3] = commit_list = [
            %Server.Commit{
                filename: "file1.test",
                timestamp: 0,
                message: "test one"
            },
            %Server.Commit{
                filename: "file1.test",
                timestamp: 2,
                message: "test two"
            },
            %Server.Commit{
                filename: "file1.test",
                timestamp: 1,
                message: "test three"
            }
        ]
        [_, m2, _] = machine_list = Enum.take(machines, 3)

        # Add each commit to one different machine
        Enum.zip(commit_list, machine_list)
        |> Enum.each(fn {commit, machine} ->
            Server.Commit.add_node(commits, commit, machine)
        end)

        # Add latest commit to another machine
        m4 = Enum.at(machines, 3)
        Server.Commit.add_node(commits, Enum.at(commit_list, 1), m4)

        assert Server.Commit.get_commits(commits, "file1.test") == {:ok, [c2, c3, c1]}
        assert Server.Commit.get_latest_commit(commits, "file1.test") == {:ok, Enum.at(commit_list, 1)}
        assert Server.Commit.get_nodes_latest_commits(commits, "file1.test") == [m4, m2]

    end

    test "all combinations", %{commits: commits} do
        m1 = :foo@m1
        m2 = :bar@m2
        m3 = :baz@m3
        m4 = :rubmary@m4

        commit_list = for i <- 0..3, j <- 0..4, do: %Server.Commit{
            filename: "file #{i}",
            timestamp: rem(j+2, 5)*10+i,
            message: "file #{i} - timestamp #{rem(j+2, 5)*10+i}"
        }

        commit_messages = for i <- 0..3, do: {
            "file #{i}",
            (for j <- 0..4, do: {(4-j)*10+i,  "file #{i} - timestamp #{(4-j)*10+i}"})
        }

        machine_list = [
            [m1, m3],
            [m1, m2],
            [m2, m3],
            [m2, m4],
            [m4, m1],
            [m1, m2, m3],
            [m1, m2, m4],
            [m2, m3, m4],
            [m1, m3, m4],
            [m1, m2, m3],
            [m3, m4],
            [m3, m2],
            [m1, m2],
            [m2, m3],
            [m2, m3, m4],
            [m1, m3, m4],
            [m2, m4],
            [m1, m2, m3],
            [m4],
            [m3]
        ]

        zipped = List.zip([commit_list, machine_list])

        for {commit, machines} <- zipped, do:
            Server.Commit.add_nodes(commits, commit, machines)

        for {commit, machines} <- zipped, do:
            assert Server.Commit.get_nodes(commits, commit.filename, commit.timestamp) == machines

        for {filename, messages} <- commit_messages do
            Server.Commit.get_commits(commits, filename)
            |> elem(1)
            |> Enum.map(fn c -> {c.timestamp, c.message} end)
            |> (fn c -> assert( c == messages ) end).()
        end

        for {filename, [{timestamp, message} | _]} <- commit_messages do
            assert Server.Commit.get_latest_commit(commits, filename) == {:ok, 
                %Server.Commit{
                    filename: filename,
                    timestamp: timestamp,
                    message: message
                }
            }
        end

        for {n, {filename, time_messages}} <- List.zip([[1, 2, 3, 4], commit_messages]) do
            assert Server.Commit.get_latest_commits(commits, filename, n) == {:ok,
                Enum.map(Enum.take(time_messages, n), fn {timestamp, message} ->
                    %Server.Commit {
                        filename: filename,
                        timestamp: timestamp,
                        message: message
                    }
                end)
            }
        end

        # Agregar tests cuando se agregan un commit repetido (con el mismo timestamp) y una maquina repetida
        # new_machine = [m1, m2, m3, m4, m4, m3, m2, m1, m1, m2, m2, m4, m3, m2, m1, m2, m3, m1, m4]

    end
end
