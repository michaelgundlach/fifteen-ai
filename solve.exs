# Map Boards to
# - parent (to find 4-parent)
# - 4-descendents (to easily find the leaves to expand to 5-depth)
# - distance to start (for posterity - always choose him immediately when found as a leaf unless he's in our ancestry in which case never)
defmodule Data do
  @n SolverAgent

  def init do
    {parents, leaves, distances} = { %{}, %{}, %{} }
    {:ok, pid} = Agent.start_link(fn -> {parents, leaves, distances} end)
    Process.register(pid, @n)
  end

  def exists(child), do: Agent.get(@n, fn {p, _, _} -> Map.has_key?(p, child) end)
  def set_parent(child, parent), do: Agent.update(@n, fn {parents, leaves, distances} -> {Map.put(parents, child, parent), leaves, distances} end)
  def parent(child), do: Agent.get(@n, fn {parents, _leaves, _distances} -> parents[child] end)
  def set_distance(child, distance), do: Agent.update(@n, fn {parents, leaves, distances} -> {parents, leaves, Map.put(distances, child, distance)} end)
  def distance(child), do: Agent.get(@n, fn {_parents, _leaves, distances} -> distances[child] end)
  def add_leaf(child, leaf), do: Agent.update(@n, fn {parents, leaves, distances} -> {parents, Map.update(leaves, child, [], fn acc -> [leaf|acc] end), distances} end)
  def leaves(child), do: Agent.get(@n, fn {_parents, leaves, _distances} -> Map.get(leaves, child, []) end)
end

defmodule Solve do
  @lookahead_depth 11 

  def ancestor(board), do: ancestor(board, @lookahead_depth - 1)
  def ancestor(board, 0), do: board
  def ancestor(board, n), do: ancestor(Data.parent(board), n-1)

  def solve(board) do
    Data.init
    record(board, nil, 0)
    all_descendents = init_descendents(board, 0) |> :lists.flatten
    best_descendent = all_descendents |> Enum.min_by(&(&1.suckiness))

    do_solve(board, {best_descendent, Data.distance(best_descendent)})
  end

  def record(board, parent, distance) do
    if not Data.exists board do
      Data.set_parent(board, parent)
      Data.set_distance(board, distance)
    end
  end

  # Sets parent and distance for all board's descendents up to @lookahead_depth.
  # Set start board's leaves.
  # Returns board's descendents as an unflattened list.
  def init_descendents(board, @lookahead_depth-2) do
    make_leaf_offspring board
  end
  def init_descendents(board, current_depth) do
    kids = Board.legal_plays(board)
    # Don't merge the .each and .map, to record kids breadth-first instead
    # of depth-first.  That way if a kid is found twice, he'll be credited
    # correctly with the shorter path to the root.
    Enum.each kids, fn kid ->
      record(kid, board, current_depth + 1)
    end
    Enum.map kids, fn kid ->
      [kid | init_descendents(kid, current_depth + 1)]
    end
  end

  # Grows kids one level beneath |leaf| and returns them in a list.
  def make_leaf_offspring leaf do
    kids = Board.legal_plays(leaf) # NB: filtering out parent(leaf) doesn't speed up solve()
    kid_dist = Data.distance(leaf) + 1
    kids_ancestor = ancestor(leaf, @lookahead_depth - 2)
    Enum.each kids, fn kid ->
      record(kid, leaf, kid_dist)
      Data.add_leaf(kids_ancestor, kid)
    end
    kids
  end

  #board must have .leaves filled
  # returns list of boards ending in solution or a local maximum
  def do_solve(board, {best, depth}) do
    all_kids = Enum.flat_map Data.leaves(board), &make_leaf_offspring/1
    # TODO - handle finding previously-discovered but unvisited nodes with much shorter distance-to-start
    best_kid = Enum.min_by(all_kids, fn kid -> kid.suckiness end)

    cond do
      # Found solution
      best_kid.suckiness == 0 -> path_from_root(best_kid)
      # Found better solution than |best| - start heading toward it
      best_kid.suckiness < best.suckiness -> do_solve(ancestor(best_kid), {best_kid, @lookahead_depth - 1})
      # No better solution than |best| - keep heading toward it
      depth > 0 -> do_solve(ancestor(best, depth-1), {best, depth - 1})
      # |best| was |board| - we can't go any farther without looking deeper than @lookahead_depth.
      true ->
        IO.puts "Got stuck in a #{@lookahead_depth}-deep local maximum."
        path_from_root(best)
    end
  end

  def path_from_root(board), do: path_from_root(board, [])
  def path_from_root(board, acc) do
    case Data.parent(board) do
      nil -> [board|acc]
      parent -> path_from_root(parent, [board|acc])
    end
  end
end

