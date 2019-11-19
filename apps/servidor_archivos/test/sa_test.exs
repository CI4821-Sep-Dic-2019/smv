defmodule SATest do
  use ExUnit.Case, async: true
  doctest SA

  setup do
    File.rm "file.test-123"
    :ok
  end
  test "getting a file" do
    assert SA.get_file({"file.test", 123}) == {:error, :enoent}
    assert SA.put_file({"file.test", 123}, "#include<map>") == :ok

    assert SA.get_file({"file.test", 123}) == {:ok, "#include<map>"}
  end
end
