problem = Board.from_string("eacdbfghijklmno_")
#problem = Board.from_string("gbcdafemijklonh_")
path = Solve.solve problem
IO.puts "Length of path: #{Enum.count(path)}.  Final board:"
IO.inspect hd(:lists.reverse(path))
IO.puts "------"
path |> Enum.each(&IO.puts/1)
