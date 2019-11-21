defmodule ServerTest.Commit do
    use ExUnit.Case, async: true

    setup do
        commits = start_supervised!(Server.Commit)
        %{commits: commits}
    end

    test "add and fetch commits' info", %{commits: commits} do
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
            Server.Commit.add_machines(commits, commit, machines)

        for {commit, machines} <- zipped, do:
            assert Server.Commit.get_nodes(commits, commit.filename, commit.timestamp) == machines

        for {filename, messages} <- commit_messages, do:
            assert Server.Commit.get_filename_commits(commits, filename) == messages

        for {filename, [{timestamp, message} | _]} <- commit_messages, do:
            assert Server.Commit.get_latest_commit(commits, filename) == %Server.Commit{
                filename: filename,
                timestamp: timestamp,
                message: message
            }

        for {n, {filename, time_messages}} <- List.zip([[1, 2, 3, 4], commit_messages]), do:
            assert Server.Commit.get_latest_commits(commits, filename, n) ==
                Enum.map(Enum.take(time_messages, n), fn {timestamp, message} ->
                    %Server.Commit {
                        filename: filename,
                        timestamp: timestamp,
                        message: message
                    }
                end
        )

        # Agregar tests cuando se agregan un commit repetido (con el mismo timestamp) y una maquina repetida
        # new_machine = [m1, m2, m3, m4, m4, m3, m2, m1, m1, m2, m2, m4, m3, m2, m1, m2, m3, m1, m4]

    end
end
