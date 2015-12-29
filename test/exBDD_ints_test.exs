defmodule ExBDDIntsTest do
  use ExUnit.Case, async: true
  doctest ExBDD.Ints
  import ExBDD.Ints

  test "make_ints" do
    {:ok, base} = ExBDD.init
    assert [[1,4,7],[2,5,8],[3,6,9]] == (make_ints base, ["a","b","c"], 3)
  end

  @tag timeout: 800000000
  test "add" do
    {:ok, base} = ExBDD.init
    [a,b,c,d,e,f,g,h] = (make_ints base, ["a","b","c","d","e","f","g","h"], n=32)
    IO.puts "------- a + b --------------"
    sumAB = add base, a, b
    IO.puts "------- c + d --------------"
    sumCD = add base, c, d
    assert (Enum.count sumAB) == n
    assert (Enum.count sumCD) == n

		IO.puts "------- ab + cd ------------"
    sumABCD = add base, sumAB, sumCD
    assert (Enum.count sumABCD) == n

		IO.puts "------- e + f --------------"
    sumEF = add base, e, f
    IO.puts "------- g + h --------------"
    sumGH = add base, g, h
    assert (Enum.count sumEF) == n
    assert (Enum.count sumGH) == n

		IO.puts "------- ef + gh ------------"
    sumEFGH = add base, sumEF, sumGH
    assert (Enum.count sumEFGH) == n

		IO.puts "----- abcd + efgh ----------"
    sumABCDEFGH = add base, sumABCD, sumEFGH
    assert (Enum.count sumABCDEFGH) == n
  end


end
