defmodule ExBDDTest do
  use ExUnit.Case
  doctest ExBDD
  import Bitwise

  @o 0; @l -1

  setup do
    {:ok, base} = ExBDD.init
    {:ok, base: base}
  end

  test "variables", %{base: base} do
    [a, b] = ExBDD.vars base, ["a", "b"]
    assert [a, b] == [1, 2]
    [na, nb] = [(bnot a), (bnot b)]
    assert (ExBDD.get_bdd base, a) == { a, @l, @o }
    assert (ExBDD.get_bdd base, b) == { b, @l, @o }
    assert (ExBDD.get_bdd base, na) == { a, @o, @l }
    assert (ExBDD.get_bdd base, nb) == { b, @o, @l }
  end


  test "bAND", %{base: base} do
    [a, b] = ExBDD.vars base, ["a", "b"]
    f = ExBDD.bAND base, a, b
    g = ExBDD.bAND base, b, a
    assert f == g
    assert (ExBDD.get_bdd base, f) == { a, b, @o }
    assert (ExBDD.whenHi base, a, f) == b
    assert (ExBDD.whenLo base, a, f) == @o
    assert (ExBDD.whenHi base, b, f) == a
    assert (ExBDD.whenLo base, b, f) == @o
  end

  test "bNAND", %{base: base} do
    [a, b] = ExBDD.vars base, ["a", "b"]
    nf = ExBDD.bAND base, a, b
    f = ExBDD.bNAND base, a, b
    assert f == bnot nf
    assert (ExBDD.whenLo base, a, f) == @l
    assert (ExBDD.whenHi base, a, f) == bnot b
    assert (ExBDD.whenLo base, b, f) == @l
    assert (ExBDD.whenHi base, b, f) == bnot a
  end

  test "bOR", %{base: base} do
    [a, b] = ExBDD.vars base, ["a", "b"]
    f = ExBDD.bOR base, a, b
    assert (ExBDD.whenLo base, a, f) == b
    assert (ExBDD.whenHi base, a, f) == @l
    assert (ExBDD.whenLo base, b, f) == a
    assert (ExBDD.whenHi base, b, f) == @l
  end

  test "bXOR", %{base: base} do
    [a, b] = ExBDD.vars base, ["a", "b"]
    f = ExBDD.bXOR base, a, b
    assert (ExBDD.whenLo base, a, f) == b
    assert (ExBDD.whenHi base, a, f) == bnot b
    assert (ExBDD.whenLo base, b, f) == a
    assert (ExBDD.whenHi base, b, f) == bnot a
  end

  test "bMAJ", %{base: base} do
    [a, b, c] = ExBDD.vars base, ["a", "b", "c"]
    f = ExBDD.bMAJ base, a, b, c
    g = ExBDD.bMAJ base, c, a, b
    assert f == g

    assert (ExBDD.whenLo base, a, f) == (ExBDD.bAND base, b, c)
    assert (ExBDD.whenLo base, b, f) == (ExBDD.bAND base, a, c)
    assert (ExBDD.whenLo base, c, f) == (ExBDD.bAND base, a, b)
    assert (ExBDD.whenHi base, a, f) == (ExBDD.bOR base, b, c)
    assert (ExBDD.whenHi base, b, f) == (ExBDD.bOR base, a, c)
    assert (ExBDD.whenHi base, c, f) == (ExBDD.bOR base, a, b)
  end

end
