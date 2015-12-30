defmodule ExBDD.Redis do
  import Exredis.Api

  defstruct client: nil

  def connect do
    {:ok, c} = Exredis.start_link
    base = %ExBDD.Redis{client: c}
    if (exists c, "#nodes") == 0 do
      set c, 0, o = "-1,0,0"
      set c, o, 0
      set c, "#nodes", 0
      set c, "#memos", 0
    end
    base
  end

end

defimpl ExBDD.Base, for: ExBDD.Redis do
  import Bitwise
  import Exredis.Api

  @spec int(String.t | atom) :: number | nil
  defp int(x) do
    cond do
      is_integer(x) -> x
      x == :undefined -> nil
      true -> {n, _} = Integer.parse(x); n
    end
  end

  @spec bdd(String.t | atom) :: String.t | nil
  defp bdd({f,g,h}) do
    Enum.join [f,g,h], ","
  end

  @o 0; @l -1
  @type base :: ExBDD.RamCache
  @type var :: ExBDD.var
  @type bdd :: ExBDD.bdd
  @type nid :: ExBDD.nid

  @spec stats(base) :: [nodes: number, memos: number]
  def stats(base) do
    c = base.client
    [nodes: int(get c, "#nodes"), memos: int(get c, "#memos")]
  end

  @spec by_name(base, String.t) :: nid | nil
  @doc "retrieve the nids for the given name, if defined"
  def by_name(base, name) do
    (get base.client, "$" <> name) |> int
  end

  @spec new_var(base, String.t) :: var
  @doc "create a new node and bind the name to it"
  def new_var(base, name) do
    c = base.client
    nid = int(incr c, "#nodes")
    set c, nid, (bdd {nid, @l, @o})
    key = "$" <> name
    set c, key, nid
    sadd c, "@vars", key
    nid
  end

  @spec get_bdd(base, nid) :: bdd
  @doc "retrieve the if/then/else tuple for the given nid"
  def get_bdd(base, nid) do
    invert = nid < 0
    if invert do nid = bnot nid end
    [f, g, h] = (get base.client, nid) |> (String.split ",") |> Enum.map &int(&1)
    if invert do {f, (bnot g), (bnot h)} else {f, g, h} end
  end

  @spec put_memo(base, bdd, nid) :: nid
  def put_memo(base, fgh, nid) do
    set base.client, bdd(fgh), nid
    incr base.client, "#memos"
    nid
  end

  @spec get_memo(base, nid, nid, nid) :: nid | nil
  @doc "return the memoized nid for (ite f,g,h), if present"
  def get_memo(base, f, g, h) do
    int(get base.client, (bdd {f,g,h}))
  end

  @spec get_nid(base, bdd) :: nid
  @doc "find or create a nid for this triple."
  def get_nid(base, {f, g, h}) do
    if (memo = get_memo base, f, g, h) != nil do memo
    else
      c = base.client
      nid = int(incr c, "#nodes")
      set c, nid, bdd({ f, g, h })
      put_memo(base, {f, g, h}, nid)
    end
  end

end
