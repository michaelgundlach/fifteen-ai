# Map Boards to
# - parent (to find 4-parent)
# - 4-descendents (to easily find the leaves to expand to 5-depth)
# - distance to start (for posterity - always choose him immediately when found as a leaf unless he's in our ancestry in which case never)
defmodule Data do
  @n SolverAgent
  # Record maps are {parent, leaves, distance}

  def init do
    {parents, leaves, distances} = { %{}, %{}, %{} }
    {:ok, pid} = Agent.start_link(fn -> {parents, leaves, distances})
    Process.register(pid, @name)
  end

  def set_parent(child, parent), do: Agent.update(@n, fn {parents, leaves, distances} -> {Map.put(parents, child, parent), leaves, distances} end)
  def parent(child), do: Agent.get(@n, fn {parents, _leaves, _distances} -> parents[child] end)
  def set_distance(child, distance), do: Agent.update(@n, fn {parents, leaves, distances} -> {parents, leaves, Map.put(distances, child, distance)} end)
  def distance(child), do: Agent.get(@n, fn {_parents, _leaves, distances} -> distances[child] end)
  def add_leaf(child, leaf), do: Agent.update(@n, fn {parents, leaves, distances} -> {parents, Map.update(leaves, child, [], fn acc -> [leaf|acc] end), distances} end)
  def leaves(child), do: Agent.get(@n, fn {_parents, leaves, _distances} -> Map.get(leaves, child, []) end)
end

defmodule Solve do
  @lookahead_depth=5

  def solve(board) do
    Data.init
    bestchoice = init(board)
    path = do_solve(board, bestchoice)
    IO.puts "Length of path: #{Enum.count(path)}.  Final board:"
    IO.inspect hd(:lists.reverse(path))
  end

  def init(startboard) do
    Data.set_parent(startboard, nil)
    Data.set_distance(startboard, 0)
    init_data(startboard, startboard)
    {best, score, depth} = TODO #  - find best scoring board B in all 1-thru-4-descendents of A and create best-choice [B/S/D/?]
  end

  def init_data(startboard, board, depth_remaining \\ @lookahead_depth-1) do
    children = Board.legal_plays(board)
    dist = Data.distance(board)
    Enum.each children, fn child ->
      Data.set_parent(child, board)
      Data.set_distance(child, dist+1)
      if depth_remaining == 0, do: Data.add_leaf(startboard, child)
    end
  end

  def do_solve(board, {best, score, depth}, map) do
    # return List of boards ending in solution or a local maximum
  end

end

# If we were at a node with best-choice [board=C/score=S/depth=5/next-on-path-to-board=N], then we recurse on N and do the following:
# # N must know its 4-descendents
# # All descendents up to 4-descendents must know their parents and distance to start
# RECURSE(N, best-choice=[C/S/D/?]):
# - %{N}.4-descendents.each L:
#   - make kids for L.  kids.each K:
#     - %{K}.parent = L
#     - %{K}.distance to start = %{L}.distance + 1
#     - (K's 4-parent).4-descendents.prepend(K)
#       [possible optimization: only do the above line for the 4-descendents of the 4-parent of the best kid.  But then we need to
#        deal with if we find a rejected alternate path later.  Not worth it.]
# - Best kid B = min(all kids scores) # TODO - handle finding previously-discovered nodes with much shorter distance-to-start
# - If B's score is perfect:
#   - RETURN the full path from B to start node, in reverse.
# - If B's score beats S:
#   RECURSE(B's 4-parent, [B/B's score/4/?])
# - Else if D is > 0:
#   RECURSE(C's (D-1)-parent, [C/S/D-1/?])
# - Else
#   - RETURN the full path from C to start node, with a message that we're stuck in a local maximum.
