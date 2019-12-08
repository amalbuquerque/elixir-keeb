defmodule ElixirKeebTest do
  use ExUnit.Case
  doctest ElixirKeeb

  test "greets the world" do
    assert [:world, _timestamp] = ElixirKeeb.hello()
  end
end
