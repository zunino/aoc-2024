#+feature dynamic-literals

package d06

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:testing"

NORMAL_CELL :: '.'
OBSTACLE_CELL :: '#'
GUARD_CELL :: '^'

CellType :: enum {
	Normal,
	Obstacle,
}

Cell :: struct {
	type:    CellType,
	visited: bool,
}

Vec2 :: distinct [2]int

Heading :: enum {
	Up,
	Right,
	Down,
	Left,
}

VisitedObstacle :: struct {
	position: Vec2,
	heading:  Heading,
}

heading_vectors := [Heading]Vec2 {
	.Up    = {0, -1},
	.Right = {1, 0},
	.Down  = {0, 1},
	.Left  = {-1, 0},
}

next_heading := [Heading]Heading {
	.Up    = .Right,
	.Right = .Down,
	.Down  = .Left,
	.Left  = .Up,
}

LabMap :: struct {
	locations:      [dynamic][dynamic]Cell,
	rows, cols:     int,
	guard_position: Vec2,
	guard_heading:  Heading,
}

@(private)
parse_lab_map :: proc(data: string) -> LabMap {
	contents := data
	y := 0
	cols := strings.index(contents, "\n")
	locations: [dynamic][dynamic]Cell
	guard_position := Vec2{}
	for line in strings.split_lines_iterator(&contents) {
		trimmed := strings.trim_space(line)
		row: [dynamic]Cell
		for c, x in trimmed {
			switch c {
			case OBSTACLE_CELL:
				append(&row, Cell{type = CellType.Obstacle})
			case GUARD_CELL:
				guard_position.x = x
				guard_position.y = y
				fallthrough
			case:
				append(&row, Cell{type = CellType.Normal})
			}
		}
		append(&locations, row)
		y += 1
	}
	return LabMap{locations, y, cols, guard_position, Heading.Up}
}

@(private)
read_lab_map_from_file :: proc(path: string) -> LabMap {
	data, ok := os.read_entire_file_from_filename(path)
	if !ok {
		panic("Failed to read file")
	}
	defer delete(data)
	return parse_lab_map(string(data))
}

@(private)
free_lab_map :: proc(lab_map: ^LabMap) {
	for row in lab_map.locations {
		delete(row)
	}
	delete(lab_map.locations)
}

@(private)
step_forward :: proc(position: Vec2, heading: Heading) -> Vec2 {
	heading_vec := heading_vectors[heading]
	new_position := Vec2{position.x + heading_vec.x, position.y + heading_vec.y}
	return new_position
}

@(private)
back_out_and_turn_right :: proc(position: Vec2, heading: Heading) -> (Vec2, Heading) {
	heading_vec := heading_vectors[heading]
	new_position := Vec2{position.x - heading_vec.x, position.y - heading_vec.y}
	new_heading := next_heading[heading]
	return new_position, new_heading
}

@(private)
is_valid_position :: proc(lab_map: ^LabMap, position: Vec2) -> bool {
	return(
		position.x >= 0 &&
		position.x < lab_map.cols &&
		position.y >= 0 &&
		position.y < lab_map.rows \
	)
}

@(private)
traverse_lab_map :: proc(
	lab_map: ^LabMap,
	cell_callback: proc(_: ^LabMap, _: ^Cell, _: ^int),
) -> int {
	position := &lab_map.guard_position
	heading := &lab_map.guard_heading
	accumulator := 0
	for is_valid_position(lab_map, position^) {
		cell := &lab_map.locations[position.y][position.x]
		if cell.type == CellType.Obstacle {
			position^, heading^ = back_out_and_turn_right(position^, heading^)
			continue
		}
		cell_callback(lab_map, cell, &accumulator)
		position^ = step_forward(position^, heading^)
	}
	return accumulator
}

@(private)
part_1 :: proc(lab_map: ^LabMap) -> int {
	count_distinct_positions_visited :: proc(
		lab_map: ^LabMap,
		current_cell: ^Cell,
		accumulator: ^int,
	) {
		if !current_cell.visited {
			accumulator^ += 1
			current_cell.visited = true
		}
	}
	distinct_positions_visited := traverse_lab_map(lab_map, count_distinct_positions_visited)
	return distinct_positions_visited
}

@(private)
look_for_obstacle :: proc(lab_map: ^LabMap, position: Vec2, heading: Heading) -> Maybe(Vec2) {
	switch heading {
	case .Right:
		for x := position.x + 1; x < lab_map.cols; x += 1 {
			if lab_map.locations[position.y][x].type == .Obstacle do return Vec2{x, position.y}
		}
	case .Down:
		for y := position.y + 1; y < lab_map.rows; y += 1 {
			if lab_map.locations[y][position.x].type == .Obstacle do return Vec2{position.x, y}
		}
	case .Left:
		for x := position.x - 1; x >= 0; x -= 1 {
			if lab_map.locations[position.y][x].type == .Obstacle do return Vec2{x, position.y}
		}
	case .Up:
		for y := position.y - 1; y >= 0; y -= 1 {
			if lab_map.locations[y][position.x].type == .Obstacle do return Vec2{position.x, y}
		}
	}
	return nil
}

@(private)
check_for_loop :: proc(lab_map: ^LabMap, obstacle_pos: Vec2) -> bool {
	new_obstacle_cell := &lab_map.locations[obstacle_pos.y][obstacle_pos.x]
	if new_obstacle_cell.type != .Normal {
		return false
	}
	new_obstacle_cell.type = .Obstacle
	defer new_obstacle_cell.type = .Normal

	position := lab_map.guard_position
	heading := lab_map.guard_heading

	visited_obstacles: [dynamic]VisitedObstacle
	defer delete(visited_obstacles)

	for {
		possible_next_obstacle_pos := look_for_obstacle(lab_map, position, heading)
		if possible_next_obstacle_pos == nil do return false
		next_obstacle_pos := possible_next_obstacle_pos.(Vec2)
		visited_obstacle := VisitedObstacle {
			position = next_obstacle_pos,
			heading  = heading,
		}
		if slice.contains(visited_obstacles[:], visited_obstacle) do return true
		append(&visited_obstacles, visited_obstacle)
		position, heading = back_out_and_turn_right(next_obstacle_pos, heading)
	}

	return false
}

/*
Part 2 had me struggling for some 3 days. Running my solution on the sample data was
giving the expected results, but with the actual data, the value was above the target.
I was quite close to the correct result; the problem was finding the edge case(s) I
was missing. Most common cases reported on the subreddit I was already taking care of.
I was feeling really frustrated and disappointed in me, until I found this one post
(https://www.reddit.com/r/adventofcode/comments/1hb9odk/comment/m1fd32u/). It allowed
me to find the last piece of the puzzle. I hadn't realized that, by dynamically adding
candidate obstacles as the solution simulated the guard's traversal of the map, it
would eventually detected loops that wouldn't have happened if the guard's initial
position were taken into consideration. The {3, 3} position suggested in the reddit
comment was the key to my realizing what was going wrong. The solution was to keep
track of candidate obstacle positions that had been tried and failed to cause a loop
(the `discarded_candidates` collection below).
*/
@(private)
part_2 :: proc(lab_map: ^LabMap) -> int {
	@(static) discarded_candidates: [dynamic]Vec2
	@(static) selected_candidates: [dynamic]Vec2
	defer delete(discarded_candidates)
	defer delete(selected_candidates)
	count_obstruction_positions :: proc(lab_map: ^LabMap, current_cell: ^Cell, accumulator: ^int) {
		position := lab_map.guard_position
		heading := lab_map.guard_heading
		candidate_position := position + heading_vectors[heading]
		if !is_valid_position(lab_map, candidate_position) do return
		if check_for_loop(lab_map, candidate_position) {
			if !slice.contains(discarded_candidates[:], candidate_position) &&
			   !slice.contains(selected_candidates[:], candidate_position) {
				accumulator^ += 1
				append(&selected_candidates, candidate_position)
			}
		} else {
			append(&discarded_candidates, candidate_position)
		}
	}
	traverse_lab_map(lab_map, count_obstruction_positions)
	return len(selected_candidates)
}

main :: proc() {
	lab_map_path := "d06/d06.txt"
	if len(os.args) == 2 && os.args[1] == "sample" {
		lab_map_path = "d06/sample-input.txt"
	}

	lab_map := read_lab_map_from_file(lab_map_path)
	distinct_positions_visited := part_1(&lab_map)
	fmt.println("Part 1:", distinct_positions_visited)
	free_lab_map(&lab_map)

	lab_map = read_lab_map_from_file(lab_map_path)
	loop_causing_obstruction_positions := part_2(&lab_map)
	fmt.println("Part 2:", loop_causing_obstruction_positions)
	free_lab_map(&lab_map)
}

@(private)
make_testing_lab_map :: proc() -> LabMap {
	return parse_lab_map(
		"...#....\n" +
		".......#\n" +
		".#......\n" +
		".....#..\n" +
		"..#.....\n" +
		"....#...\n" +
		".^......\n" +
		"........",
	)
}

@(test)
test_look_for_obstacle_right :: proc(t: ^testing.T) {
	lab_map := make_testing_lab_map()
	defer free_lab_map(&lab_map)
	obstacle_position := look_for_obstacle(&lab_map, Vec2{1, 3}, Heading.Right)
	testing.expect_value(t, obstacle_position, Vec2{5, 3})
}

@(test)
test_look_for_obstacle_down :: proc(t: ^testing.T) {
	lab_map := make_testing_lab_map()
	defer free_lab_map(&lab_map)
	obstacle_position := look_for_obstacle(&lab_map, Vec2{4, 3}, Heading.Down)
	testing.expect_value(t, obstacle_position, Vec2{4, 5})
}

@(test)
test_look_for_obstacle_left :: proc(t: ^testing.T) {
	lab_map := make_testing_lab_map()
	defer free_lab_map(&lab_map)
	obstacle_position := look_for_obstacle(&lab_map, Vec2{4, 4}, Heading.Left)
	testing.expect_value(t, obstacle_position, Vec2{2, 4})
}

@(test)
test_look_for_obstacle_up :: proc(t: ^testing.T) {
	lab_map := make_testing_lab_map()
	defer free_lab_map(&lab_map)
	obstacle_position := look_for_obstacle(&lab_map, Vec2{3, 4}, Heading.Up)
	testing.expect_value(t, obstacle_position, Vec2{3, 0})
}
