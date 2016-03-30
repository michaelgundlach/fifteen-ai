defmodule Astar do
  alias HeapQueue, as: PQ

  def path(start, goal, gen_legal_moves, scorer) do
    steps = 0
    pri = pri(start, steps, scorer)
    pq = PQ.new() |> PQ.push(pri, {start, steps, [start]})
    seen = MapSet.new
    path_to(goal, gen_legal_moves, scorer, pq, seen)
  end

  def path_to(goal, gen_legal_moves, scorer, pq, seen) do
    {{:value, _, {guess, guess_steps, path_to_guess}}, pq} = PQ.pop(pq)
    if rem(PQ.size(pq), 2000) < 2 do
      IO.puts "PQ size: #{PQ.size pq}.  SeenSet size: #{MapSet.size(seen)}"
      IO.puts "Value: #{guess} (#{guess_steps} steps, score=#{guess.suckiness})"
    end
    if guess == goal do
      IO.puts "Solved: path length = #{guess_steps}"
      path_to_guess |> :lists.reverse |> Enum.each(&IO.puts/1)
    else
      move_steps = guess_steps + 1
      {pq, seen} = gen_legal_moves.(guess)
            |> Enum.reject(&(MapSet.member? seen, &1))
            |> Enum.reduce({pq, seen}, fn move, {pq, seen} ->
              pri = pri(move, move_steps, scorer)
              pq = PQ.push(pq, pri, {move, move_steps, [move|path_to_guess]})
              seen = MapSet.put(seen, move)
              {pq, seen}
            end)
      path_to(goal, gen_legal_moves, scorer, pq, seen)
    end
  end

  def pri(move, steps, scorer), do: steps + scorer.(move)
end
