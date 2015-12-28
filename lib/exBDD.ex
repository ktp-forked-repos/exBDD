defmodule ExBDD do
  @doc """
  Binary Decision Diagram module for Elixir.
  © Copyright 2015 Michal J Wallace <http://tangentstorm.com/>
  Available for use under the MIT license.

  Based on the 1990 paper, _Efficient Implementation of a BDD Package_,
  by Karl S. Brace, Richard L. Rudell, and Randal E. Bryant.
  """
  import Bitwise

  @o 0; @l -1

  @doc """
  :: nid, nid, nid, default? -> nid | default
  -- return the memoized nid for (ite f,g,h), if present
  """
  def get_memo( _f, _g, _h, default \\ nil ) do
    default # TODO: actually look up memos
  end

  @doc """
  :: nid -> nid
  -- return the nid for the variable or function on which node n branches
  """
  def get_var( n ) do
    if n < 0 do n = bnot n end
    if n == @o do @l else n end # TODO: handle more than variables
  end

  @doc """
  :: nid, nid, nid → nid | {nid, nid, nid} | %{not: {nid,nid,nid}
  -- normalize if/then/else triples.
  """
  def ite_norm(f, g, h) do
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
      {^f, ^f, ^h} -> ite_norm f, @l,  h
      {^f, ^g, ^f} -> ite_norm f,  g, @o
      {^f, ^g,^nf} -> ite_norm f,  g, @l
      {^f,^nf, ^h} -> ite_norm f, @o,  h
      _ ->
        # Choose between equivalent forms by putting the smaller variable in the 'if' slot.
        [fv, gv, hv] = for x <- [f, g, h] do get_var x end
        case {g, h} do
          {@l, ^h} when hv < fv -> ite_norm  h, @l,  f  # (f?l:g) = (g?l:f)
          {^g, @o} when gv < fv -> ite_norm  g,  f, @o  # (f?g:o) = (g?f:o)
          {^g, @l} when gv < fv -> ite_norm ng, nf, @l  # (f?g:l) = (¬g?¬f:l)
          {@o, ^h} when hv < fv -> ite_norm nh, @o, nf  # (f?o:h) = (¬h?o:¬f)
          {^g,^ng} when gv < fv -> ite_norm  g,  f, nf  # (f?g:¬g) = (g?f:¬f)
          _ ->
            # choose the representation with non-complemented edges in the 'if' and 'then' slots.
            # 0. (f ? g : h);  1. (¬f ? h : g);  2. ¬(f ? ¬g : ¬h)  3. ¬(¬f ? ¬h : ¬g)
            cond do
              f < 0 -> ite_norm nf, h, g
              g < 0 ->
                r = ite_norm f, ng, nh
                if is_integer r do bnot r else %{ not: r } end
              # that's all we can do. the triple is now fully normalized:
              true -> get_memo f, g, h, {f, g, h}
            end
        end
    end
  end

end
