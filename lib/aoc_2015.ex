defmodule AdventOfCode do
  import Bitwise
  def solve(day, part) do
    case read_input(day) do
      {:ok, input} -> apply(__MODULE__, String.to_atom("day#{day}_part#{part}"), [input])
      {:error, reason} -> {:error, "Failed to read input: #{reason}"}
    end
  end

  defp read_input(day) do
    possible_paths = [
      "inputs/input#{day}.txt",
      "lib/inputs/input#{day}.txt",
      "input#{day}.txt"
    ]

    Enum.find_value(possible_paths, {:error, :not_found}, fn path ->
      case File.read(path) do
        {:ok, content} -> {:ok, String.trim(content)}
        _ -> nil
      end
    end)
  end

  # Day 1 solutions
  def day1_part1(input) do
    input
    |> String.graphemes()
    |> Enum.reduce(0, fn
      "(", acc -> acc + 1
      ")", acc -> acc - 1
      _, acc -> acc
    end)
  end

  def day1_part2(input) do
    input
    |> String.graphemes()
    |> Enum.with_index(1)
    |> Enum.reduce_while({0, nil}, fn
      {"(", _}, {floor, nil} -> {:cont, {floor + 1, nil}}
      {")", i}, {0, nil} -> {:halt, {-1, i}}
      {")", _}, {floor, nil} when floor > 0 -> {:cont, {floor - 1, nil}}
      _, {floor, position} -> {:cont, {floor, position}}
    end)
    |> elem(1)
  end


  # Day 2 solutions
  def day2_part1(input) do
    input
    |> String.split("\n")
    |> Enum.map(&calculate_wrapping_paper/1)
    |> Enum.sum()
  end

  def day2_part2(input) do
    input
    |> String.split("\n")
    |> Enum.map(&calculate_ribbon/1)
    |> Enum.sum()
  end

  defp calculate_wrapping_paper(dimensions) do
    [l, w, h] = dimensions |> String.split("x") |> Enum.map(&String.to_integer/1)
    areas = [l*w, w*h, h*l]
    2 * Enum.sum(areas) + Enum.min(areas)
  end

  defp calculate_ribbon(dimensions) do
    [a, b, c] = dimensions |> String.split("x") |> Enum.map(&String.to_integer/1) |> Enum.sort()
    2*(a + b) + a*b*c
  end

  # Day 3 solutions
  def day3_part1(input) do
    input
    |> String.graphemes()
    |> count_houses(&move/2, [{0, 0}])
    |> MapSet.size()
  end

  def day3_part2(input) do
    input
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.reduce({MapSet.new([{0, 0}]), {0, 0}, {0, 0}}, fn
      {direction, index}, {visited, santa_pos, robo_pos} ->
        if rem(index, 2) == 0 do
          new_pos = move(santa_pos, direction)
          {MapSet.put(visited, new_pos), new_pos, robo_pos}
        else
          new_pos = move(robo_pos, direction)
          {MapSet.put(visited, new_pos), santa_pos, new_pos}
        end
    end)
    |> elem(0)
    |> MapSet.size()
  end

  def day4_part1(input) do
    find_adventcoin(input, 5)
  end

  def day4_part2(input) do
    find_adventcoin(input, 6)
  end
  def day5_part1(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.count(&nice_string?/1)
  end

  def day5_part2(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.count(&nice_string_part2?/1)
  end


  # Day 6 solutions
  def day6_part1(input) do
    grid = :array.new(1_000_000, default: 0)

    input
    |> String.split("\n", trim: true)
    |> Enum.reduce(grid, &process_instruction/2)
    |> :array.to_list()
    |> Enum.sum()
  end

  def day6_part2(input) do
    grid = :array.new(1_000_000, default: 0)

    input
    |> String.split("\n", trim: true)
    |> Enum.reduce(grid, &process_instruction_brightness/2)
    |> :array.to_list()
    |> Enum.sum()
  end

  defp process_instruction(instruction, grid) do
    [action | coords] = String.split(instruction)
    [start_x, start_y, end_x, end_y] = coords |> List.flatten() |> Enum.map(&String.to_integer/1)

    for x <- start_x..end_x, y <- start_y..end_y do
      index = y * 1000 + x
      case action do
        "toggle" -> :array.set(index, 1 - :array.get(index, grid), grid)
        "turn" <> " on" -> :array.set(index, 1, grid)
        "turn" <> " off" -> :array.set(index, 0, grid)
      end
    end
  end

  defp process_instruction_brightness(instruction, grid) do
    [action | coords] = String.split(instruction)
    [start_x, start_y, end_x, end_y] = coords |> List.flatten() |> Enum.map(&String.to_integer/1)

    for x <- start_x..end_x, y <- start_y..end_y do
      index = y * 1000 + x
      current = :array.get(index, grid)
      case action do
        "toggle" -> :array.set(index, current + 2, grid)
        "turn" <> " on" -> :array.set(index, current + 1, grid)
        "turn" <> " off" -> :array.set(index, max(0, current - 1), grid)
      end
    end
  end

  # Day 7 solutions
  def day7_part1(input) do
    circuit = parse_circuit(input)
    evaluate_wire("a", circuit, %{})
  end

  def day7_part2(input) do
    circuit = parse_circuit(input)
    a_value = evaluate_wire("a", circuit, %{})
    new_circuit = Map.put(circuit, "b", fn _ -> a_value end)
    evaluate_wire("a", new_circuit, %{})
  end

  defp parse_circuit(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_instruction/1)
    |> Enum.into(%{})
  end

  defp parse_instruction(instruction) do
    [operation, wire] = String.split(instruction, " -> ")
    {wire, parse_operation(operation)}
  end

  defp parse_operation(operation) do
    cond do
      String.contains?(operation, "AND") ->
        [a, b] = String.split(operation, " AND ")
        fn cache -> bitwise_and(a, b, cache) end
      String.contains?(operation, "OR") ->
        [a, b] = String.split(operation, " OR ")
        fn cache -> bitwise_or(a, b, cache) end
      String.contains?(operation, "LSHIFT") ->
        [a, b] = String.split(operation, " LSHIFT ")
        fn cache -> lshift(a, String.to_integer(b), cache) end
      String.contains?(operation, "RSHIFT") ->
        [a, b] = String.split(operation, " RSHIFT ")
        fn cache -> rshift(a, String.to_integer(b), cache) end
      String.starts_with?(operation, "NOT") ->
        [_, a] = String.split(operation, "NOT ")
        fn cache -> bitwise_not(a, cache) end
      true ->
        fn cache -> evaluate_operand(operation, cache) end
    end
  end

  defp evaluate_wire(wire, circuit, cache) do
    case Map.get(cache, wire) do
      nil ->
        {value, new_cache} = circuit[wire].(circuit, cache)
        {value, Map.put(new_cache, wire, value)}
      value ->
        {value, cache}
    end
  end

  defp evaluate_operand(operand, circuit, cache) do
    case Integer.parse(operand) do
      {int, ""} -> {int, cache}
      _ -> evaluate_wire(operand, circuit, cache)
    end
  end

  defp bitwise_and(a, b, cache), do: band(evaluate_operand(a, cache), evaluate_operand(b, cache))
  defp bitwise_or(a, b, cache), do: bor(evaluate_operand(a, cache), evaluate_operand(b, cache))
  defp lshift(a, b, cache), do: evaluate_operand(a, cache) <<< b
  defp rshift(a, b, cache), do: evaluate_operand(a, cache) >>> b
  defp bitwise_not(a, cache), do: bnot(evaluate_operand(a, cache)) &&& 0xFFFF

  # Day 8 solutions
  def day8_part1(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      code_chars = String.length(line)
      memory_chars = line
        |> Code.string_to_quoted!()
        |> to_string()
        |> String.length()
      code_chars - memory_chars
    end)
    |> Enum.sum()
  end

  def day8_part2(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      encoded = line
        |> String.replace("\\", "\\\\")
        |> String.replace("\"", "\\\"")
      String.length(~s("#{encoded}")) - String.length(line)
    end)
    |> Enum.sum()
  end

  # Day 9 solutions
  def day9_part1(input) do
    distances = parse_distances(input)
    cities = Map.keys(distances) |> Enum.uniq()
    permutations(cities)
    |> Enum.map(&route_distance(&1, distances))
    |> Enum.min()
  end

  def day9_part2(input) do
    distances = parse_distances(input)
    cities = Map.keys(distances) |> Enum.uniq()
    permutations(cities)
    |> Enum.map(&route_distance(&1, distances))
    |> Enum.max()
  end

  defp parse_distances(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.reduce(%{}, fn line, acc ->
      [cities, distance] = String.split(line, " = ")
      [city1, city2] = String.split(cities, " to ")
      distance = String.to_integer(distance)
      acc
      |> Map.put({city1, city2}, distance)
      |> Map.put({city2, city1}, distance)
    end)
  end

  defp permutations([]), do: [[]]
  defp permutations(list) do
    for elem <- list, rest <- permutations(list -- [elem]), do: [elem | rest]
  end

  defp route_distance([city1, city2 | rest], distances) do
    distances[{city1, city2}] + route_distance([city2 | rest], distances)
  end
  defp route_distance([_], _), do: 0

  # Day 10 solutions
  def day10_part1(input) do
    Enum.reduce(1..40, input, fn _, acc ->
      look_and_say(acc)
    end)
    |> String.length()
  end

  def day10_part2(input) do
    Enum.reduce(1..50, input, fn _, acc ->
      look_and_say(acc)
    end)
    |> String.length()
  end
  def day11_part1(input) do
    next_valid_password(input)
  end

  def day11_part2(input) do
    input
    |> next_valid_password()
    |> next_valid_password()
  end

  defp next_valid_password(password) do
    password
    |> increment_password()
    |> Stream.iterate(&increment_password/1)
    |> Enum.find(&valid_password?/1)
  end

  defp increment_password(password) do
    password
    |> String.reverse()
    |> increment_string()
    |> String.reverse()
  end

  defp increment_string("z" <> rest), do: "a" <> increment_string(rest)
  defp increment_string(<<c>> <> rest), do: <<c + 1>> <> rest
  defp increment_string(""), do: "a"

  defp valid_password?(password) do
    has_increasing_straight?(password) and
    no_forbidden_letters?(password) and
    has_two_pairs?(password)
  end

  defp has_increasing_straight?(password) do
    password
    |> String.to_charlist()
    |> Enum.chunk_every(3, 1, :discard)
    |> Enum.any?(fn [a, b, c] -> c == b + 1 and b == a + 1 end)
  end

  defp no_forbidden_letters?(password) do
    not String.match?(password, ~r/[iol]/)
  end

  defp has_two_pairs?(password) do
    password
    |> String.to_charlist()
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.filter(fn [a, b] -> a == b end)
    |> Enum.uniq()
    |> length()
    |> Kernel.>=(2)
  end

  # Day 12 solutions
  def day12_part1(input) do
    ~r/-?\d+/
    |> Regex.scan(input)
    |> List.flatten()
    |> Enum.map(&String.to_integer/1)
    |> Enum.sum()
  end

  def day12_part2(input) do
    input
    |> Jason.decode!()
    |> sum_numbers()
  end

  defp sum_numbers(data) when is_map(data) do
    if Enum.any?(Map.values(data), &(&1 == "red")) do
      0
    else
      Enum.sum(Enum.map(Map.values(data), &sum_numbers/1))
    end
  end
  defp sum_numbers(data) when is_list(data) do
    Enum.sum(Enum.map(data, &sum_numbers/1))
  end
  defp sum_numbers(data) when is_number(data), do: data
  defp sum_numbers(_), do: 0

  # Day 13 solutions
  def day13_part1(input) do
    happiness_map = parse_happiness(input)
    people = Map.keys(happiness_map) |> Enum.uniq()

    people
    |> permutations()
    |> Enum.map(&calculate_happiness(&1, happiness_map))
    |> Enum.max()
  end

  def day13_part2(input) do
    happiness_map = parse_happiness(input)
    people = Map.keys(happiness_map) |> Enum.uniq()

    happiness_map = Enum.reduce(people, happiness_map, fn person, acc ->
      acc
      |> Map.put({"You", person}, 0)
      |> Map.put({person, "You"}, 0)
    end)

    (["You" | people])
    |> permutations()
    |> Enum.map(&calculate_happiness(&1, happiness_map))
    |> Enum.max()
  end

  defp parse_happiness(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.reduce(%{}, fn line, acc ->
      [person1, _, action, amount, _, _, _, _, _, _, person2] = String.split(line)
      amount = if action == "gain", do: String.to_integer(amount), else: -String.to_integer(amount)
      Map.put(acc, {person1, String.trim(person2, ".")}, amount)
    end)
  end

  defp calculate_happiness(arrangement, happiness_map) do
    arrangement
    |> Enum.zip(tl(arrangement) ++ [hd(arrangement)])
    |> Enum.reduce(0, fn {a, b}, acc ->
      acc + Map.get(happiness_map, {a, b}, 0) + Map.get(happiness_map, {b, a}, 0)
    end)
  end

  # Day 14 solutions
  def day14_part1(input) do
    reindeer = parse_reindeer(input)
    Enum.map(reindeer, &distance_after_time(&1, 2503))
    |> Enum.max()
  end

  def day14_part2(input) do
    reindeer = parse_reindeer(input)

    1..2503
    |> Enum.reduce(%{}, fn second, scores ->
      distances = Enum.map(reindeer, &{&1.name, distance_after_time(&1, second)})
      max_distance = Enum.map(distances, &elem(&1, 1)) |> Enum.max()

      Enum.reduce(distances, scores, fn {name, distance}, acc ->
        if distance == max_distance do
          Map.update(acc, name, 1, &(&1 + 1))
        else
          acc
        end
      end)
    end)
    |> Map.values()
    |> Enum.max()
  end

  defp parse_reindeer(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      [name, _, _, speed, _, _, fly_time, _, _, _, _, _, _, rest_time, _] = String.split(line)
      %{
        name: name,
        speed: String.to_integer(speed),
        fly_time: String.to_integer(fly_time),
        rest_time: String.to_integer(rest_time)
      }
    end)
  end

  defp distance_after_time(reindeer, time) do
    cycle_time = reindeer.fly_time + reindeer.rest_time
    full_cycles = div(time, cycle_time)
    remaining_time = rem(time, cycle_time)

    full_distance = full_cycles * reindeer.speed * reindeer.fly_time
    extra_distance = min(remaining_time, reindeer.fly_time) * reindeer.speed

    full_distance + extra_distance
  end

  # Day 15 solutions
  def day15_part1(input) do
    ingredients = parse_ingredients(input)
    generate_combinations(length(ingredients), 100)
    |> Enum.map(&score_recipe(&1, ingredients))
    |> Enum.max()
  end

  def day15_part2(input) do
    ingredients = parse_ingredients(input)
    generate_combinations(length(ingredients), 100)
    |> Enum.filter(&(calories(&1, ingredients) == 500))
    |> Enum.map(&score_recipe(&1, ingredients))
    |> Enum.max()
  end

  defp parse_ingredients(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      [name | properties] = String.split(line, ~r/[,:]\s*/)
      properties = Enum.chunk_every(properties, 2)
      |> Enum.map(fn [k, v] -> {String.to_atom(k), String.to_integer(v)} end)
      |> Enum.into(%{})
      {name, properties}
    end)
    |> Enum.into(%{})
  end

  defp generate_combinations(1, total), do: [[total]]
  defp generate_combinations(n, total) do
    for i <- 0..total,
        rest <- generate_combinations(n - 1, total - i),
        do: [i | rest]
  end

  defp score_recipe(amounts, ingredients) do
    properties = [:capacity, :durability, :flavor, :texture]
    scores = Enum.map(properties, fn prop ->
      score = Enum.zip(amounts, Map.values(ingredients))
      |> Enum.map(fn {amount, ingredient} -> amount * ingredient[prop] end)
      |> Enum.sum()
      max(0, score)
    end)
    Enum.product(scores)
  end

  defp calories(amounts, ingredients) do
    Enum.zip(amounts, Map.values(ingredients))
    |> Enum.map(fn {amount, ingredient} -> amount * ingredient.calories end)
    |> Enum.sum()
  end

  # Day 16 solutions
  def day16_part1(input) do
    aunts = parse_aunts(input)
    target = %{
      children: 3, cats: 7, samoyeds: 2, pomeranians: 3, akitas: 0,
      vizslas: 0, goldfish: 5, trees: 3, cars: 2, perfumes: 1
    }

    Enum.find(aunts, fn {_, aunt} ->
      Enum.all?(aunt, fn {k, v} -> target[k] == v end)
    end)
    |> elem(0)
  end

  def day16_part2(input) do
    aunts = parse_aunts(input)
    target = %{
      children: 3, cats: 7, samoyeds: 2, pomeranians: 3, akitas: 0,
      vizslas: 0, goldfish: 5, trees: 3, cars: 2, perfumes: 1
    }

    Enum.find(aunts, fn {_, aunt} ->
      Enum.all?(aunt, fn
        {:cats, v} -> v > target.cats
        {:trees, v} -> v > target.trees
        {:pomeranians, v} -> v < target.pomeranians
        {:goldfish, v} -> v < target.goldfish
        {k, v} -> target[k] == v
      end)
    end)
    |> elem(0)
  end

  defp parse_aunts(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      [sue, rest] = String.split(line, ": ", parts: 2)
      properties = rest
      |> String.split(", ")
      |> Enum.map(fn prop ->
        [k, v] = String.split(prop, ": ")
        {String.to_atom(k), String.to_integer(v)}
      end)
      |> Enum.into(%{})
      {String.to_integer(String.slice(sue, 4..-1)), properties}
    end)
    |> Enum.into(%{})
  end

  # Day 17 solutions
  def day17_part1(input) do
    containers = parse_containers(input)
    combinations(containers)
    |> Enum.count(&(Enum.sum(&1) == 150))
  end

  def day17_part2(input) do
    containers = parse_containers(input)
    valid_combinations = combinations(containers)
    |> Enum.filter(&(Enum.sum(&1) == 150))

    min_containers = Enum.min_by(valid_combinations, &length/1) |> length()
    Enum.count(valid_combinations, &(length(&1) == min_containers))
  end

  defp parse_containers(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.map(&String.to_integer/1)
  end

  defp combinations([]), do: [[]]
  defp combinations([h|t]) do
    for(l <- combinations(t), do: [h|l]) ++ combinations(t)
  end

  # Day 18 solutions
  def day18_part1(input) do
    grid = parse_grid(input)
    Enum.reduce(1..100, grid, fn _, acc -> step(acc) end)
    |> Map.values()
    |> Enum.count(&(&1 == "#"))
  end

  def day18_part2(input) do
    grid = parse_grid(input)
    |> turn_on_corners()

    Enum.reduce(1..100, grid, fn _, acc ->
      step(acc) |> turn_on_corners()
    end)
    |> Map.values()
    |> Enum.count(&(&1 == "#"))
  end

  defp parse_grid(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {row, y}, acc ->
      String.graphemes(row)
      |> Enum.with_index()
      |> Enum.reduce(acc, fn {cell, x}, inner_acc ->
        Map.put(inner_acc, {x, y}, cell)
      end)
    end)
  end

  defp step(grid) do
    Enum.reduce(grid, %{}, fn {{x, y}, _}, acc ->
      neighbors = count_neighbors(grid, x, y)
      new_state = case grid[{x, y}] do
        "#" when neighbors in 2..3 -> "#"
        "." when neighbors == 3 -> "#"
        _ -> "."
      end
      Map.put(acc, {x, y}, new_state)
    end)
  end

  defp count_neighbors(grid, x, y) do
    for dx <- -1..1, dy <- -1..1, {dx, dy} != {0, 0} do
      grid[{x + dx, y + dy}]
    end
    |> Enum.count(&(&1 == "#"))
  end

  defp turn_on_corners(grid) do
    size = round(:math.sqrt(map_size(grid))) - 1
    corners = [{0, 0}, {0, size}, {size, 0}, {size, size}]
    Enum.reduce(corners, grid, fn corner, acc ->
      Map.put(acc, corner, "#")
    end)
  end

 

  defp look_and_say(string) do
    string
    |> String.graphemes()
    |> Enum.chunk_by(&(&1))
    |> Enum.map(fn chunk -> "#{length(chunk)}#{hd(chunk)}" end)
    |> Enum.join()
  end


  defp nice_string?(str) do
    has_three_vowels?(str) and has_double_letter?(str) and not has_forbidden_strings?(str)
  end

  defp has_three_vowels?(str) do
    str
    |> String.graphemes()
    |> Enum.count(&(&1 in ~w(a e i o u)))
    |> Kernel.>=(3)
  end

  defp has_double_letter?(str) do
    String.match?(str, ~r/(.)\1/)
  end

  defp has_forbidden_strings?(str) do
    String.match?(str, ~r/(ab|cd|pq|xy)/)
  end

  defp nice_string_part2?(str) do
    has_pair_twice?(str) and has_repeat_with_one_between?(str)
  end

  defp has_pair_twice?(str) do
    String.match?(str, ~r/(..).*\1/)
  end

  defp has_repeat_with_one_between?(str) do
    String.match?(str, ~r/(.).\1/)
  end
  defp find_adventcoin(secret_key, zero_count) do
    Stream.iterate(1, &(&1 + 1))
    |> Enum.find(fn number ->
      hash = :crypto.hash(:md5, "#{secret_key}#{number}") |> Base.encode16()
      String.starts_with?(hash, String.duplicate("0", zero_count))
    end)
  end
  defp count_houses(directions, move_fn, initial) do
    Enum.reduce(directions, {MapSet.new(initial), hd(initial)}, fn direction, {visited, current_pos} ->
      new_pos = move_fn.(current_pos, direction)
      {MapSet.put(visited, new_pos), new_pos}
    end)
    |> elem(0)
  end

  defp move({x, y}, direction) do
    case direction do
      "^" -> {x, y + 1}
      "v" -> {x, y - 1}
      ">" -> {x + 1, y}
      "<" -> {x - 1, y}
    end
  end

end

# Usage example with error handling
Enum.each 1..30, fn day ->
  Enum.each 1..2, fn part ->
    case AdventOfCode.solve(day, part) do
      {:error, message} -> IO.puts "Day #{day}, Part #{part}: #{message}"
      result -> IO.puts "Day #{day}, Part #{part}: #{result}"
    end
  end
end
