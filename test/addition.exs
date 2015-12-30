import ExBDD.Ints

base = ExBDD.Redis.connect
[a,b,c,d,e,f,g,h] = (make_ints base, ["a","b","c","d","e","f","g","h"], n=32)

IO.puts "------- a + b --------------"
sumAB = add base, a, b
IO.puts "------- c + d --------------"
sumCD = add base, c, d

IO.puts "------- ab + cd ------------"
sumABCD = add base, sumAB, sumCD


IO.puts "------- e + f --------------"
sumEF = add base, e, f
IO.puts "------- g + h --------------"
sumGH = add base, g, h

IO.puts "------- ef + gh ------------"
sumEFGH = add base, sumEF, sumGH


IO.puts "----- abcd + efgh ----------"
sumABCDEFGH = add base, sumABCD, sumEFGH
