defmodule Astar do
  alias HeapQueue, as: PQ

  def path(start, goal, gen_legal_moves, scorer) do
    pq = PQ.new() |> PQ.push(0 + scorer.(start), {start, 0, [start]})
    path_to(goal, gen_legal_moves, scorer, pq)
  end

  def path_to(goal, gen_legal_moves, scorer, pq) do
    {{:value, _, {guess, guess_steps, path_to_guess}}, pq} = PQ.pop(pq)
    IO.puts "PQ size: #{PQ.size pq}.  value: #{guess}, steps: #{guess_steps}"
    if guess == goal do
      IO.puts "Solved: path length = #{guess_steps}"
      IO.inspect (path_to_guess |> :lists.reverse)
    else
      pq = Enum.reduce gen_legal_moves.(guess), pq, fn move, pq ->
        pri = guess_steps + scorer.(move)
        path_to_move = [move | path_to_guess]
        PQ.push(pq, pri, {move, guess_steps + 1, path_to_move})
      end
      path_to(goal, gen_legal_moves, scorer, pq)
    end
  end
end
