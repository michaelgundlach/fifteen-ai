#problem = Board.from_string("eacdbfghijklmno_")
problem = Board.from_string("dmcebahokfignlj_")
goal = Board.from_string(   "abcdefghijklmno_")
Astar.path(problem, goal, &Board.legal_plays/1, &(&1.suckiness))
