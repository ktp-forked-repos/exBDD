defmodule ExBDD do
  @doc """
  Binary Decision Diagram module for Elixir.
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
        [fv, gv, hv] = for x <- [f, g, h] do get_var x end
        case {g, h} do
          {@l, ^h} when hv < fv -> ite_norm  h, @l,  f
          {^g, @o} when gv < fv -> ite_norm  g,  f, @o
          {^g, @l} when gv < fv -> ite_norm ng, nf, @l
          {@o, ^h} when hv < fv -> ite_norm nh, @o, nf
          {^g,^ng} when gv < fv -> ite_norm  g,  f, nf
          _ ->
            cond do
              f < 0 -> ite_norm nf, h, g
              g < 0 ->
                r = ite_norm f, ng, nh
                if is_integer r do bnot r else %{ not: r } end
              true -> get_memo f, g, h, {f, g, h}
            end
        end
    end
  end

end
