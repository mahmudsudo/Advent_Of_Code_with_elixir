defmodule AocElixirTest do
  use ExUnit.Case
  doctest AocElixir

  test "greets the world" do
    assert is_number(AocElixir.part1())
  end
end
