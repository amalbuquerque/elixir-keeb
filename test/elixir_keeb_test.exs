defmodule ElixirKeebTest do
  use ExUnit.Case
  doctest ElixirKeeb

  test "greets the world" do
    assert ElixirKeeb.hello() == :world
  end
end
