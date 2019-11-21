defmodule SATest do
    use ExUnit.Case, async: true
    doctest SA

    setup do
        File.rm "../../files/file.test-123"
        File.rm "../../files/test.pdf-2"
        commit = %Server.Commit{
            filename: "file.test",
            timestamp: 123,
            message: "message"
        }
        %{commit: commit}
    end

    test "getting a file",  %{commit: commit} do
        content =
            '''
            File to test files :D
                - Rubmary Rojas
                - Gustavo Castellanos
                - Constanza (no me acuerdo tu apellido >.<)
            '''
        assert SA.get_file(commit) == {:error, :enoent}
        assert SA.put_file(commit, content) == :ok
        assert SA.get_file(commit) == {:ok, to_string(content)}

        # Get and put pdf
        commit1 = %Server.Commit{
            filename: "test.pdf",
            timestamp: 1,
            message: "test pdf"
        }

        commit2 = %Server.Commit{
            filename: "test.pdf",
            timestamp: 2,
            message: "test pdf"
        }

        {:ok, content} = SA.get_file(commit1)
        assert SA.put_file(commit2, content) == :ok
        assert SA.get_file(commit2) == {:ok, to_string(content)}
    end
end
