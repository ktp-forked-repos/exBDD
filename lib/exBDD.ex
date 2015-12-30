defmodule ExBDD do
  @doc """
  Binary Decision Diagram module for Elixir.
  © Copyright 2015 Michal J Wallace <http://tangentstorm.com/>
  Available for use under the MIT license.

  Based on the 1990 paper, _Efficient Implementation of a BDD Package_,
  by Karl S. Brace, Richard L. Rudell, and Randal E. Bryant.
  """
  import Bitwise

  # node 0 (@o) is the false node. instead of a 'true' node, we
  # just create a complement edge to the 'false' node. (@l = bnot @o)
  @o 0; @l -1

  @typdoc "node identifier"
  @type nid :: number

  @typdoc "nid for a variable"
  @type var :: nid

  @typdoc "if/then/else triple"
  @type bdd :: {nid, nid, nid}

  @typdoc "reference to BDD base"
  @type base :: pid

  @spec init :: base
  @doc "create a new BDD base"
  def init do
    Agent.start_link fn ->
      %{nodes: %{ 0 => { @l, @o, @l } },
        names: %{ },
        memos: %{ },
        next_nid: 1 }
    end
  end

  @spec stats(base) :: [nodes: number, memos: number]
  def stats(base) do
    Agent.get base, fn state ->
      [nodes: Enum.count(state[:nodes]), memos: Enum.count(state[:memos])]
    end
  end

  @spec vars(base, [String.t]) :: [var]
  @doc "retrieve the nids for the given variables (creating new nodes when necessary)"
  def vars(base, names) do
    for v <- names do by_name(base, v) || new_var(base, v) end
  end

  @spec by_name(base, String.t) :: nid | nil
  @doc "retrieve the nids for the given name, if defined"
  def by_name(base, name) do
    Agent.get base, fn %{names: names} -> names[name] end
  end

  @spec new_var(base, String.t) :: var
  @doc "create a new node and bind the name to it"
  def new_var(base, name) do
    Agent.get_and_update base, fn state ->
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
    Agent.get base, fn state ->
      invert = nid < 0
      if invert do nid = bnot nid end
      {f, g, h} = state[:nodes][nid]
      if invert do {f, (bnot g), (bnot h)} else {f, g, h} end
    end
  end

  @spec bAND(base, nid, nid) :: nid
  @doc "perform a logical AND operation on BDD nodes"
  def bAND(base, a, b), do: ite base, a, b, @o

  @spec bNAND(base, nid, nid) :: nid
  @doc "perform a logical NAND operation on BDD nodes"
  def bNAND(base, a, b), do: bnot(ite base, a, b, @o)

  @spec bOR(base, nid, nid) :: nid
  @doc "perform a logical OR operation on BDD nodes"
  def bOR(base, a, b), do: ite base, a, @l, b

  @spec bXOR(base, nid, nid) :: nid
  @doc "perform a logical XOR operation on BDD nodes"
  def bXOR(base, a, b), do: ite base, a, (bnot b), b

  @spec bMAJ(base, nid, nid, nid) :: nid
  @doc "perform a Majority operation on BDD nodes"
  def bMAJ(base, a, b, c) do
    [x, y, z] = Enum.sort_by [a, b, c], fn n -> get_var base, n end
    ite(base, x, ite(base, y, @l, z),
                 ite(base, y, z, @o))
  end

  @spec get_memo(base, nid, nid, nid) :: nid | nil
  @doc "return the memoized nid for (ite f,g,h), if present"
  def get_memo(base, f, g, h, default \\ nil ) do
    Agent.get base, fn state ->
      Map.get(state[:memos], {f, g, h}, default)
    end
  end

  @spec put_memo(base, bdd, nid) :: nid
  def put_memo(base, fgh, nid) do
    Agent.update base, fn state ->
      %{state | memos: Map.put(state[:memos], fgh, nid)}
    end
    nid
  end


  @spec get_nid(base, nid, nid, nid) :: nid
  @doc "find or create a nid for this triple."
  def get_nid(base, f, g, h) do
    if (memo = get_memo base, f, g, h) != nil do memo
    else
      Agent.get_and_update base, fn state ->
        nid = state[:next_nid]
        {nid, %{state |
                next_nid: nid + 1,
                nodes: Map.put(state[:nodes], nid, {f,g,h}),
                memos: Map.put(state[:memos], {f,g,h}, nid)}}
      end
    end
  end

  @spec get_var(base, nid) :: var
  @doc "return the nid for the variable or function on which node n branches"
  def get_var(base, n) do
    cond do
      n < 0 -> get_var base, (bnot n)
      n == @o -> @l
      true -> {f, _g, _h} = (get_bdd base, n); f
    end
  end

  @spec ite_norm(base, nid, nid, nid) :: nid | bdd | %{not: bdd}
  @doc "normalize if/then/else triples."
  def ite_norm(base, f, g, h) do
    nf = bnot f; ng= bnot g; nh= bnot h
    case {f, g, h} do
      # Perform some standard simplifications:
      {@l, ^g, ^h} -> g
      {@o, ^g, ^h} -> h
      {^f, ^g, ^g} -> g
      {^f, @l, @o} -> f
      {^f, @o, @l} -> nf
      {^f, ^f, @o} -> f
      {^f, ^f, @l} -> @l
      {^f, ^f, ^h} -> ite_norm base, f, @l,  h
      {^f, ^g, ^f} -> ite_norm base, f,  g, @o
      {^f, ^g,^nf} -> ite_norm base, f,  g, @l
      {^f,^nf, ^h} -> ite_norm base, f, @o,  h
      _ ->
        # Choose between equivalent forms by putting the smaller variable in the 'if' slot.
        [fv, gv, hv] = for x <- [f, g, h] do get_var base, x end
        case {g, h} do
          {@l, ^h} when hv < fv -> ite_norm base,  h, @l,  f  # (f?l:g) = (g?l:f)
          {^g, @o} when gv < fv -> ite_norm base,  g,  f, @o  # (f?g:o) = (g?f:o)
          {^g, @l} when gv < fv -> ite_norm base, ng, nf, @l  # (f?g:l) = (¬g?¬f:l)
          {@o, ^h} when hv < fv -> ite_norm base, nh, @o, nf  # (f?o:h) = (¬h?o:¬f)
          {^g,^ng} when gv < fv -> ite_norm base,  g,  f, nf  # (f?g:¬g) = (g?f:¬f)
          _ ->
            # choose the representation with non-complemented edges in the 'if' and 'then' slots.
            # 0. (f ? g : h);  1. (¬f ? h : g);  2. ¬(f ? ¬g : ¬h)  3. ¬(¬f ? ¬h : ¬g)
            cond do
              f < 0 -> ite_norm base, nf, h, g
              g < 0 ->
                r = ite_norm base, f, ng, nh
                if is_integer r do bnot r else %{ not: r } end
              # that's all we can do. the triple is now fully normalized:
              true -> {f, g, h}
            end
        end
    end
  end

  @spec ite(base, nid, nid, nid) :: nid
  @doc "if/then/else operation"
  def ite(base, f, g, h) do
    case ite_norm base, f, g, h do
      {f, g, h} -> build_ite base, f, g, h
      %{not: {f, g, h}} -> bnot (build_ite base, f, g, h)
      nid when is_integer(nid) -> nid
    end
  end

  @spec build_ite(base, nid, nid, nid) :: nid
  @doc "recursively build a new bdd for the given if/then/else triple"
  def build_ite(base, f, g, h) do
    if (res = get_memo base, f, g, h) != nil do res
    else
      vars = for n <- [f,g,h] do get_var base, n end
      if_ = Enum.min(for v <- vars, v > 0, do: v)

      # consider spawning a new task:
      spawn? = (:random.uniform(4) == 1)
      if spawn? do
        pc = :erlang.system_info(:process_count)
        if (:random.uniform(1024)==1), do: IO.inspect [processes: pc] ++ stats base
      end
      th_ = if spawn? do
        Task.async ExBDD, :ite, [base | for n <- [f,g,h] do whenHi(base, if_, n) end]
      else
        apply ExBDD, :ite, [base | for n <- [f,g,h] do whenHi(base, if_, n) end]
      end
      el_ = apply ExBDD, :ite, [base | for n <- [f,g,h] do whenLo(base, if_, n) end]
      if spawn? do th_ = Task.await th_, ms = 100000000 end  # timeout in ms
      result = if th_ == el_ do th_ else get_nid base, if_, th_, el_ end
      put_memo base, {f, g, h}, result
    end
  end

  @spec whenHi(base, var, nid) :: nid
  @doc "return the value of the node when var is true"
  def whenHi(base, var, nid) do
    {v, hi, lo} = get_bdd base, nid
    cond do
      v == @l -> nid
      var == v -> hi
      var < v -> nid
      var > v -> ite base, v, (whenHi base, var, hi), (whenHi base, var, lo)
    end
  end

  @spec whenHi(base, var, nid) :: nid
  @doc "return the value of the node when var is false"
  def whenLo(base, var, nid) do
    {v, hi, lo} = get_bdd base, nid
    cond do
      v == @l -> nid
      var == v -> lo
      var < v -> nid
      var > v -> ite base, v, (whenLo base, var, hi), (whenLo base, var, lo)
    end
  end

end
