problem = Board.from_string("eacdbfghijklmno_")
goal = Board.from_string(   "abcdefghijklmno_")
Astar.path(problem, goal, &Board.legal_plays/1, &(&1.suckiness))
