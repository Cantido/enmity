defmodule EnmityTest do
  use ExUnit.Case
  doctest Enmity

  test "greets the world" do
    assert Enmity.hello() == :world
  end
end
