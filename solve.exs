defmodule Board do
  # This puzzle has the letters A through O on 15 tiles, plus a blank tile.
  # Tile positions are numbered 0 through 15, left to right top to bottom.
  # e.g. solved puzzle is:
  #   tiles = %{0: :a, 1: :b, ..., 14: :o, 15: :blank}
  #   blankpos = 15
  defstruct blankpos: nil, tiles: nil

  @solvedblankpos 15
  @solvedtiles %{
           0 => :a,  1 => :b,  2 => :c,  3 => :d,
           4 => :e,  5 => :f,  6 => :g,  7 => :h,
           8 => :i,  9 => :j, 10 => :k, 11 => :l,
          12 => :m, 13 => :n, 14 => :o, 15 => :blank
        }
  defmacro solved do
    quote do: %Board{blankpos: unquote(Macro.escape @solvedblankpos),
                     tiles: unquote(Macro.escape @solvedtiles)}
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

  @doc """
  0 is solved.  Higher numbers are farther from solved.
  """
  def suckiness board do
    Enum.reduce board.tiles, 0, fn {pos, tile}, acc -> acc + distance(pos, tile) end
  end

  # Slide distance from pos to tile's correct position.
  defp distance pos, tile do
    abs(row(pos) - row(correct_pos(tile))) + 
    abs(col(pos) - col(correct_pos(tile)))
  end

  def slide_from(%Board{blankpos: blankpos, tiles: tiles}, slider_pos) do
    slider = tiles[slider_pos]
    newtiles = %{tiles | blankpos => slider, slider_pos => :blank}
    %Board{blankpos: slider_pos, tiles: newtiles}
  end

  #TODO get memoization right
  #Memoize.memoize [board] do
  def legal_plays(board=%Board{blankpos: blankpos}) do
    Enum.map neighbor_positions(blankpos), &(board |> slide_from(&1))
  end
end

defmodule GreedySolver do
  require Board
  @lookahead_depth 5

  @doc """
  List of Boards excluding current Board, to get to solution
  """
  def solution(Board.solved), do: []
  def solution(board) do
    next_board = best_next_board(board)
    [next_board | solution(next_board)]
  end

  @doc """
  Return the one Board that has the best promise several moves out.
  """
  def best_next_board(board) do
    tree = board |> MoveTree.to_depth(@lookahead_depth)
    {_score, [_tree|best_path]} = MoveTree.scored_path_to_max_leaf(tree, @lookahead_depth, &(-Board.suckiness(&1.board)))
    hd(best_path).board
  end
end

defmodule MoveTree do
  defstruct board: nil, children: nil

  def to_depth(board, 0), do: %MoveTree{board: board, children: []}
  def to_depth(board, n) do
    movetrees = Enum.map Board.legal_plays(board), fn play -> 
      to_depth(play, n-1)
    end
    %MoveTree{board: board, children: movetrees}
  end

  @doc """
  returns {score, path}, starting at tree, of |depth+1| length.
  score is score of the max leaf.
  path is a list with tree as its first element
  """
  def scored_path_to_max_leaf(tree, 0, scorer), do: {scorer.(tree), [tree]}
  def scored_path_to_max_leaf(tree, depth, scorer) do
    init_score = nil
    init_path = nil
    Enum.reduce tree.children, {init_score, init_path}, fn move, {acc_score, acc_path} ->
      {score, path} = scored_path_to_max_leaf(move, depth-1, scorer)
      if score < acc_score do # first time: (score < nil) is false
        {acc_score, acc_path}
      else
        {score, [tree|path]}
      end
    end
  end
end
