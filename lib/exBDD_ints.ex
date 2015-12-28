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
  
end
