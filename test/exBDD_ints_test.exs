defmodule ExBDDIntsTest do
  use ExUnit.Case, async: true
  doctest ExBDD.Ints
  import ExBDD.Ints

  test "make_ints" do
    base = ExBDD.init
    assert [[1,4,7],[2,5,8],[3,6,9]] == (make_ints base, ["a","b","c"], 3)
  end

end
