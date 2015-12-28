defmodule ExBDD.GenNorms do

  def format(n) when is_integer(n), do: Integer.to_string n
  def format({f, g, h}), do: "(#{Enum.join([f, g, h], ", ")})"
  def format(%{not: x}), do: "¬#{format(x)}"

  def go do
    {:ok, base} = ExBDD.init
    ExBDD.vars base, ["a", "b", "c"]
    each = [0, -1, 1, -2, 2, -3, 3, -4]
    for f <- each, g <- each, h <- each do
      IO.puts (format {f,g,h}) <> " → " <> format(ExBDD.ite_norm base, f, g, h)
    end
  end
end
ExBDD.GenNorms.go

