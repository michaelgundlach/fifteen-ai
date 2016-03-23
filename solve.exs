defmodule Board do
  # This puzzle has the letters A through O on 15 tiles, plus a blank tile.
  # Tile positions are numbered 0 through 15, left to right top to bottom.
  # e.g. solved puzzle is:
  #   tiles = %{0: :a, 1: :b, ..., 14: :o, 15: :blank}
  #   blankpos = 15
  defstruct blankpos: nil, tiles: nil, suckiness: nil

  def from(blankpos, tiles),
    do: %Board{blankpos: blankpos, tiles: tiles, suckiness: suckiness(tiles)}

  def from_string(str) do
    letters = str |> String.codepoints |> Enum.with_index
    {_, blankpos} = List.keyfind(letters, "_", 0)
    tiles = for {char, i} <- letters, into: %{} do
      {i, case char do
            "_" -> :blank
            _ -> String.to_atom char
          end}
    end
    Board.from(blankpos, tiles)
  end

  def problem, do: from_string("eacdbfghijklmno_")

  @solvedtiles %{
           0 => :a,  1 => :b,  2 => :c,  3 => :d,
           4 => :e,  5 => :f,  6 => :g,  7 => :h,
           8 => :i,  9 => :j, 10 => :k, 11 => :l,
          12 => :m, 13 => :n, 14 => :o, 15 => :blank
        }
  defmacro solved do
    quote do: %Board{blankpos: 15,
                     tiles: unquote(Macro.escape @solvedtiles),
                     suckiness: 0}
  end

  # TODO yuck so hard coded
  defp neighbor_positions(pos) do
    left = pos - 1
    right = pos + 1
    up = pos - 4
    down = pos + 4
    is_left = rem(pos, 4) == 0
    is_right = rem(pos, 4) == 3
    is_top = (pos < 4)
    is_bot = (pos > 11)
    cond do
      is_left and is_top -> [right, down]
      is_right and is_top -> [left, down]
      is_left and is_bot -> [right, up]
      is_right and is_bot -> [left, up]
      is_top -> [left, right, down]
      is_bot -> [left, right, up]
      is_left -> [up, down, right]
      is_right -> [up, down, left]
      true -> [up, down, left, right]
    end
  end

  Enum.map @solvedtiles, fn {pos, tile} ->
    def correct_pos(unquote(tile)), do: unquote(pos)
    def row(unquote(pos)), do: unquote(div(pos, 4))
    def col(unquote(pos)), do: unquote(rem(pos, 4))
  end

  # 0 is solved.  Higher numbers are farther from solved.
  defp suckiness tiles do
    Enum.reduce tiles, 0, fn {pos, tile}, acc -> acc + distance(pos, tile) end
  end

  # Slide distance from pos to tile's correct position.
  defp distance pos, tile do
    abs(row(pos) - row(correct_pos(tile))) + 
    abs(col(pos) - col(correct_pos(tile)))
  end

  def slide_from(%Board{blankpos: blankpos, tiles: tiles}, slider_pos) do
    slider = tiles[slider_pos]
    newtiles = %{tiles | blankpos => slider, slider_pos => :blank}
    Board.from(slider_pos, newtiles)
  end

  #TODO get memoization right
  #Memoize.memoize [board] do
  def legal_plays(board) when board == solved, do: [solved]
  def legal_plays(board=%Board{blankpos: blankpos}) do
    Enum.map neighbor_positions(blankpos), &(board |> slide_from(&1))
  end
end

defmodule GreedySolver do
  require Board
  @lookahead_depth 11

  @doc """
  List of Boards excluding current Board, to get to solution
  """
  def solution(board) when board == Board.solved, do: []
  def solution(board) do
    next_board = best_next_board(board)
    [next_board | solution(next_board)]
  end

  @doc """
  Return the one Board that has the best promise several moves out.
  """
  def best_next_board(board) do
    tree = MoveTree.for(board)
    {_score, _depth, best_path} = MoveTree.scored_path_to_max_node(tree, @lookahead_depth, &(-&1.board.suckiness))
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