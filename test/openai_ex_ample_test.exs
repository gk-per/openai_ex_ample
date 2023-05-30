defmodule OpenaiExAmpleTest do
  use ExUnit.Case
  doctest OpenaiExAmple

  test "greets the world" do
    assert OpenaiExAmple.hello() == :world
  end
end
