defmodule ExBDDIntsTest do
  use ExUnit.Case
  doctest ExBDD.Ints
  import ExBDD.Ints

  test "make_ints" do
    {:ok, base} = ExBDD.init
    assert [[1,4,7],[2,5,8],[3,6,9]] == (make_ints base, ["a","b","c"], 3)
  end

  test "add" do
    {:ok, base} = ExBDD.init
    [a,b,c,d] = (make_ints base, ["a","b","c","d"], n=4)
    sumAB = add base, a, b
    sumCD = add base, c, d
    assert (Enum.count sumAB) == n
    assert (Enum.count sumCD) == n

    sumABCD = add base, sumAB, sumCD
    assert (Enum.count sumABCD) == n
  end


end
