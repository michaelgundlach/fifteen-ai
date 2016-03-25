defmodule GreedySolver do
  @lookahead_depth 11

  @doc """
  List of Boards excluding current Board, to get to solution
  """
  def solution(%Board{suckiness: 0}), do: []
  def solution(board) do
    next_board = best_next_board(board)
    [next_board | solution(next_board)]
  end

  @doc """
  Return the one Board that has the best promise several moves out.
  """
  def best_next_board(board) do
    tree = MoveTree.for(board)
    {_, _, best_path} = MoveTree.scored_path_to_max_node(tree, @lookahead_depth, &(-&1.board.suckiness))
    # scored_path_to_max_node returns a 1-length path, [tree.board], if there is
    # no better board within @lookahead_depth steps.  In that case, we give up.
    # A more persistent AI would try moving at random, at least.
    if (tl best_path) == [], 
      do: raise "Gave up - no clear path forward within #{@lookahead_depth} steps"
    hd(tl best_path)
  end
end

defmodule MoveTree do
  defstruct board: nil

  def for(board), do: %MoveTree{board: board}

  def children(tree), do: Enum.map Board.legal_plays(tree.board), &(%MoveTree{board: &1})

  @doc """
  returns {score, node_depth, path}, of max |depth+1| length.
  score is score of the max node.
  node_depth is the depth of the max node relative to |head|.
  path is a list starting with |head|, ending on the max node in the next |depth|
  levels of the tree.
  """
  def scored_path_to_max_node(head, 0, scorer), do: {scorer.(head), 0, [head.board]}
  def scored_path_to_max_node(head, depth, scorer) do
    init_acc = scored_path_to_max_node(head, 0, scorer)
    Enum.reduce children(head), init_acc, fn child, {acc_score, acc_depth, acc_path} ->
      {score, node_depth, path} = scored_path_to_max_node(child, depth-1, scorer)
      cond do
        score < acc_score -> {acc_score, acc_depth, acc_path}
        score > acc_score -> {score, node_depth+1, [head.board|path]}
        node_depth < acc_depth -> {score, node_depth+1, [head.board|path]}
        true -> {acc_score, acc_depth, acc_path}
      end
    end
  end
end
