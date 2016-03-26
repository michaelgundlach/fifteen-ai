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

  @solvedtiles %{
           0 => :a,  1 => :b,  2 => :c,  3 => :d,
           4 => :e,  5 => :f,  6 => :g,  7 => :h,
           8 => :i,  9 => :j, 10 => :k, 11 => :l,
          12 => :m, 13 => :n, 14 => :o, 15 => :blank
        }

  Enum.map @solvedtiles, fn {pos, tile} ->
    def correct_pos(unquote(tile)), do: unquote(pos)
    def row(unquote(pos)), do: unquote(div(pos, 4))
    def col(unquote(pos)), do: unquote(rem(pos, 4))
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
  def legal_plays(board=%Board{suckiness: 0}), do: [board]
  def legal_plays(board=%Board{blankpos: blankpos}) do
    Enum.map neighbor_positions(blankpos), &(board |> slide_from(&1))
  end
end
