Astar.path(1, 100, fn i -> [i-1, i+i, i+i+i] end, fn i -> abs(100 - i) end)
