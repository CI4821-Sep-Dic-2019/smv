defmodule SATest do
    use ExUnit.Case, async: true
    doctest SA

    setup do
        File.rm_rf "files"
        File.mkdir "files"
        commit = %Server.Commit{
            filename: "file.test",
            timestamp: 123,
            message: "message"
        }
        %{commit: commit}
    end

    test "file name", %{commit: commit} do
        assert SA.get_name(commit) == "file.test-123"
    end

    test "getting a file",  %{commit: commit} do
        content =
            """
            File to test files :D
                - Rubmary Rojas
                - Gustavo Castellanos
                - Constanza (no me acuerdo tu apellido >.<)
            """
        assert SA.get_file(commit) == {:error, :enoent}
        assert SA.store(commit, content) == :ok
        assert SA.get_file(commit) == {:ok, to_string(content)}
    end

    test "remove a file", %{commit: commit} do
        :ok = SA.store(commit, "#include <haskell>")
        assert SA.remove(commit.filename, commit.timestamp) == :ok
        assert SA.get_file(commit) == {:error, :enoent}
    end
end
