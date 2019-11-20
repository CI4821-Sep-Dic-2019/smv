defmodule SNTest do
  use ExUnit.Case
  doctest SN

  test "greets the world" do
    assert SN.hello() == :world
  end
end
