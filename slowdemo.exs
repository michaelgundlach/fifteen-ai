# Solves a board that cannot be solved with @lookahead_depth of 5,
# because the board is in a bigger-than-5-steps local maximum of fitness.
# @lookahead_depth of 11 does work (and eats 4G RAM in the process),
# finding the path "up left left up left up right down down right right down"
# to get to the solved board.
defmodule Example do
  def solve board do
    board = GreedySolver.best_next_board board |> IO.inspect
    if board.suckiness == 0 do
      "OK"
    else
      solve board
    end
  end
end

problem = Board.from_string("eacdbfghijklmno_")

Example.solve problem
