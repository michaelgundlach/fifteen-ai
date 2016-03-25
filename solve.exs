# Map Boards to
# - parent (to find 4-parent)
# - 4-descendents (to easily find the leaves to expand to 5-depth)
# - distance to start (for posterity - always choose him immediately when found as a leaf unless he's in our ancestry in which case never)
defmodule Data do
  @n SolverAgent

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

  def ancestor(board), do: ancestor(board, @lookahead_depth - 1)
  def ancestor(board, 1), do: Data.parent(board)
  def ancestor(board, n), do: ancestor(Data.parent(board), n-1)

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
    all_descendents = init_descendents(startboard, startboard) |> :lists.flatten
    {best, score, depth} = TODO #  - find best scoring board B in all 1-thru-4-descendents of A and create best-choice [B/S/D/?]
  end

  # Sets parent and distance for all startboard's descendents up to a certain depth.
  # Set startboard's leaves.
  # Returns board's descendents as an unflattened list.
  def init_descendents(startboard, board, depth_remaining \\ @lookahead_depth-1) do
    children = Board.legal_plays(board)
    child_dist = Data.distance(board) + 1
    at_bottom_level = depth_remaining <= 1 # TODO is this right? name depth_remaining more clearly.
    Enum.each children, fn child ->
      Data.set_parent(child, board)
      Data.set_distance(child, child_dist)
      if at_bottom_level, do: Data.add_leaf(startboard, child)
    end

    if at_bottom_level do
      children
    else
      for child <- children do
        [child | init_descendents(startboard, child, depth_remaining - 1)]
      end
    end
  end

  #board must have .leaves filled
  def do_solve(board, {best, score, depth}) do
    # return List of boards ending in solution or a local maximum

    # RECURSE(N, best-choice=[C/S/D/?]):
    # - %{N}.4-descendents.each L:
    Enum.each Data.leaves(board), fn leaf ->
      kids = Board.legal_plays(leaf)
      leaf_dist = Data.distance(leaf)
      kids_ancestor = ancestor(leaf, @lookahead_depth - 2)
      Enum.each kids, fn kid ->
        Data.set_parent(kid, leaf)
        Data.set_distance(kid, leaf_dist + 1)
        Data.add_leaf(kids_ancestor, kid)
      end
    end
    # - Best kid B = min(all kids scores) # TODO - handle finding previously-discovered nodes with much shorter distance-to-start
    # - If B's score is perfect:
    #   - RETURN the full path from B to start node, in reverse.
    # - If B's score beats S:
    #   RECURSE(B's 4-parent, [B/B's score/4/?])
    # - Else if D is > 0:
    #   RECURSE(C's (D-1)-parent, [C/S/D-1/?])
    # - Else
    #   - RETURN the full path from C to start node, with a message that we're stuck in a local maximum.
  end

end

