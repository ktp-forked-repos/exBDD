defmodule ExBDD.Redis.Test do
  use ExUnit.Case
  doctest ExBDD.Ints
  import ExBDD.Base

  setup do
    base = ExBDD.Redis.connect
    {:ok, base: ExBDD.Redis.connect}
  end

  test "variables", %{base: base} do
    [x] = ExBDD.vars(base, ["test-x"])
    assert by_name(base, "test-x") == x
  end

  test "get_nid", %{base: base} do
    assert 0 == get_nid(base, {-1, 0, 0})
  end

  test "get_bdd", %{base: base} do
    assert get_bdd(base, 0) == {-1, 0, 0}
  end

  test "put_memo", %{base: base} do
    assert put_memo(base, {-1, -1, -1}, -1) == -1
  end

  test "get_memo", %{base: base} do
    assert get_memo(base, -1, 0, 0) == 0
    assert get_memo(base, -1, 1, 1) == nil
  end

  test "stats", %{base: base} do
    assert stats(base) != nil
  end

  test "simple", %{base: base} do
    [x, y] = ExBDD.vars base, ["test-x", "test-y"]
    xy = ExBDD.bAND base, x, y
    assert get_bdd(base, xy) == {x, y, 0}
    IO.puts("got here the first time")
    # now do it again to exercise the cache:
    xy = ExBDD.bAND base, x, y
    assert get_bdd(base, xy) == {x, y, 0}
    IO.puts("got here the second time")
  end

end
