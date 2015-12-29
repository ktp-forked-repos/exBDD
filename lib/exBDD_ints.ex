defmodule ExBDD.Ints do
  import ExBDD

  @typedoc "an array of bdds, corresponding to an integer."
  @type bdd_int :: [ExBDD.bdd]

  @spec make_ints(ExBDD.base, [String.t], number) :: [bdd_int]
  @doc """
  Create a bdd_int of length nbits for each prefix, interleaved like so:

  make_ints(["a","b"], 3) -> [[a1: 1, a2: 3, a3=5], [b1=2, b2=4, b3=6]]

  (This is the order that minimizes the bdd size when performing addition.)
  """
  def make_ints(base, prefixes, nbits) do
    # first, make them in the interleaved order:
    for n <- 1..nbits, pre <- prefixes do
      ExBDD.new_var(base, (pre <> Integer.to_string(n)))
    end
    # then re-fetch them, grouped by prefix
    for pre <- prefixes do
      ExBDD.vars base, (for n <- 1..nbits, do: (pre <> to_string n))
    end
  end


  @spec add(ExBDD.base, bdd_int, bdd_int) :: bdd_int
  @doc "perform addition on the 'integers'"
  def add(base, a, b) do
    Enum.count(a) == Enum.count(b) || raise(ArgumentError, message: "a and b must be the same length")
    pairs = (Enum.zip a, b) |> Enum.reverse # the pairs, from right to left
    [i: _i, c: _c, r: result] = Enum.reduce pairs, [i: 1, c: 0, r: []], fn {x, y}, [i: i, c: c, r: r] ->
			IO.puts "  step #{i} of #{Enum.count a}..."
      carry  = ExBDD.bMAJ(base, x, y, c)
      result = ExBDD.bXOR base, x, (ExBDD.bXOR base, y, c)
      [i: i+1, c: carry, r: [result|r]]
    end
    result
  end


end
