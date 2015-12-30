defmodule ExBDD.RamCache do
  defstruct pid: nil
  @o 0; @l -1

  import Bitwise

  def create do
    {:ok, pid} = Agent.start_link fn ->
      %{nodes: %{ 0 => { @l, @o, @l } },
        names: %{ },
        memos: %{ },
        next_nid: 1}
    end
    %ExBDD.RamCache{pid: pid}
  end

  defimpl ExBDD.Base, for: ExBDD.RamCache do

    @o 0; @l -1
    @type base :: ExBDD.RamCache
    @type var :: ExBDD.var
    @type bdd :: ExBDD.bdd
    @type nid :: ExBDD.nid

    @spec stats(base) :: [nodes: number, memos: number]
    def stats(base) do
      Agent.get base.pid, fn state ->
        [nodes: Enum.count(state[:nodes]), memos: Enum.count(state[:memos])]
      end
    end

    @spec by_name(base, String.t) :: nid | nil
    @doc "retrieve the nids for the given name, if defined"
    def by_name(base, name) do
      Agent.get base.pid, fn %{names: names} -> names[name] end
    end

    @spec new_var(base, String.t) :: var
    @doc "create a new node and bind the name to it"
    def new_var(base, name) do
      Agent.get_and_update base.pid, fn state ->
        nid = state[:next_nid]
        {nid, %{state |
                nodes: Map.put(state[:nodes], nid, { nid, @l, @o }),
                memos: Map.put(state[:memos], { nid, @l, @o }, nid),
                names: Map.put(state[:names], name, nid),
                next_nid: nid+1 }}
      end
    end

    @spec get_bdd(base, nid) :: bdd
    @doc "retrieve the if/then/else tuple for the given nid"
    def get_bdd(base, nid) do
      Agent.get base.pid, fn state ->
        invert = nid < 0
        if invert do nid = bnot nid end
        {f, g, h} = state[:nodes][nid]
        if invert do {f, (bnot g), (bnot h)} else {f, g, h} end
      end
    end

    @spec get_memo(base, nid, nid, nid) :: nid | nil
    @doc "return the memoized nid for (ite f,g,h), if present"
    def get_memo(base, f, g, h, default \\ nil ) do
      Agent.get base.pid, fn state ->
        Map.get(state[:memos], {f, g, h}, default)
      end
    end

    @spec put_memo(base, bdd, nid) :: nid
    def put_memo(base, fgh, nid) do
      Agent.update base.pid, fn state ->
        %{state | memos: Map.put(state[:memos], fgh, nid)}
      end
      nid
    end

    @spec get_nid(base, node) :: nid
    @doc "find or create a nid for this triple."
    def get_nid(base, {f, g, h}) do
      if (memo = get_memo base, f, g, h) != nil do memo
      else
        Agent.get_and_update base.pid, fn state ->
          nid = state[:next_nid]
          {nid, %{state |
                  next_nid: nid + 1,
                  nodes: Map.put(state[:nodes], nid, {f,g,h}),
                  memos: Map.put(state[:memos], {f,g,h}, nid)}}
        end
      end
    end

  end

end
