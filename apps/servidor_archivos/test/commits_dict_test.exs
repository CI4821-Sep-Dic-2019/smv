defmodule SATest.CommitsDict do
    use ExUnit.Case, async: true

    setup do
        dict = start_supervised!(SA.CommitsDict)
        m1 = :"foo@computer"
        m2 = :"bar@computer"
        m3 = :"baz@matrix"
        %{dict: dict, machines: [m1, m2, m3]}
    end

    test "add machines to commit", %{dict: dict, machines: [m1, m2, m3]} do
        SA.CommitsDict.add(dict, {"test_files/file.c", 124}, m1)
        SA.CommitsDict.add(dict, {"test_files/file.c", 124}, m2)
        SA.CommitsDict.add(dict, {"test_files/file.c", 125}, m3)

        assert SA.CommitsDict.get(dict, {"test_files/file.c", 124}) == [m2, m1]
        assert elem(SA.CommitsDict.get_latest(dict, "test_files/file.c"), 1) == [m3]
    end
end