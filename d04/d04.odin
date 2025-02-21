#+feature dynamic-literals

package d04

import "../util"
import "core:fmt"
import "core:strings"
import "core:testing"

remaining_chars := map[u8]string {
	'X' = "MAS",
	'S' = "AMX",
}

Vec2 :: struct {
	x: int,
	y: int,
}

Direction :: enum {
	Northwest,
	North,
	Northeast,
	East,
	Southeast,
	South,
	Southwest,
	West,
}

// row numbers grow downward
direction_vector := [Direction]Vec2 {
	Direction.Northwest = Vec2{-1, -1},
	Direction.North     = Vec2{0, -1},
	Direction.Northeast = Vec2{1, -1},
	Direction.East      = Vec2{1, 0},
	Direction.Southeast = Vec2{1, 1},
	Direction.South     = Vec2{0, 1},
	Direction.Southwest = Vec2{-1, 1},
	Direction.West      = Vec2{-1, 0},
}

Grid :: struct {
	rows:  int,
	cols:  int,
	cells: [dynamic][dynamic]u8,
}

grid_new :: proc(rows, cols: int) -> Grid {
	grid := Grid{rows, cols, make([dynamic][dynamic]u8, rows, rows)}
	for i in 0 ..< rows {
		grid.cells[i] = make([dynamic]u8, cols, cols)
	}
	return grid
}

grid_del :: proc(grid: ^Grid) {
	for i in 0 ..< grid.rows {
		delete(grid.cells[i])
	}
	delete(grid.cells)
	grid.rows = 0
	grid.cols = 0
}

grid_print :: proc(grid: Grid) {
	for i in 0 ..< grid.rows {
		for j in 0 ..< grid.cols {
			fmt.printf("%c ", grid.cells[i][j])
		}
		fmt.println()
	}
}

@(private)
find_grid_dimensions :: proc(input: string) -> (rows, cols: int) {
	newline_indices: [dynamic]int
	defer delete(newline_indices)
	for c, i in input {
		if c == '\n' {
			append(&newline_indices, i)
		}
	}
	rows = len(newline_indices) + 1
	cols = newline_indices[0]
	return
}

@(private)
make_grid_from_input :: proc(input: string) -> Grid {
	rows, cols := find_grid_dimensions(input)
	grid := grid_new(rows, cols)
	for i in 0 ..< rows {
		for j in 0 ..< cols {
			grid.cells[i][j] = input[cols * i + j + i] // the +i at the end compensates for the \n characters
		}
	}
	return grid
}

@(private)
@(link_name = "lookie")look_around :: proc(
	grid: ^Grid,
	row: int,
	col: int,
	outer_char: u8,
) -> int {
	other_chars := remaining_chars[outer_char]
	xmas_sequences_found := 0
	for direction in Direction {
		if direction < .East || direction > .Southwest do continue
		dir_vector := direction_vector[direction]
		found_chars := 0
		offset_row := row
		offset_col := col
		for i in 0 ..< len(other_chars) {
			expected_char := other_chars[i]
			offset_row += dir_vector.y
			if offset_row < 0 || offset_row >= grid.rows do break
			offset_col += dir_vector.x
			if offset_col < 0 || offset_col >= grid.cols do break
			if grid.cells[offset_row][offset_col] == expected_char {
				found_chars += 1
				continue
			}
			break
		}
		if found_chars == len(other_chars) {
			xmas_sequences_found += 1
		}
	}
	return xmas_sequences_found
}

@(private)
part_1 :: proc(input: string) -> int {
	remaining_chars := map[u8]string {
		'X' = "MAS",
		'S' = "AMX",
	}
	grid := make_grid_from_input(input)
	defer grid_del(&grid)
	outer_chars, _ := strings.ascii_set_make("XS")
	xmas_sequences_found := 0
	for i in 0 ..< grid.rows {
		for j in 0 ..< grid.cols {
			cell := grid.cells[i][j]
			if strings.ascii_set_contains(outer_chars, cell) {
				xmas_sequences_found += look_around(&grid, row = i, col = j, outer_char = cell)
			}
		}
	}
	return xmas_sequences_found
}

@(private)
@(link_name = "find_x")look_for_x_formation :: proc(
	grid: ^Grid,
	row: int,
	col: int,
	top_left_char: u8,
) -> (
	x_found: int,
) {
	end_chars := map[u8]u8 {
		'M' = 'S',
		'S' = 'M',
	}
	x_found = 0
	if row + 2 >= grid.rows || col + 2 >= grid.cols do return
	if grid.cells[row + 1][col + 1] != 'A' do return
	top_right_char := grid.cells[row][col + 2]
	if !(top_right_char in end_chars) do return
	end_char_1 := end_chars[top_left_char]
	end_char_2 := end_chars[top_right_char]
	if grid.cells[row + 2][col + 2] != end_char_1 do return
	if grid.cells[row + 2][col] != end_char_2 do return
	x_found = 1
	return
}

@(private)
part_2 :: proc(input: string) -> int {
	grid := make_grid_from_input(input)
	defer grid_del(&grid)
	outer_chars, _ := strings.ascii_set_make("MS")
	x_formations_found := 0
	for i in 0 ..< grid.rows {
		for j in 0 ..< grid.cols {
			cell := grid.cells[i][j]
			if strings.ascii_set_contains(outer_chars, cell) {
				x_formations_found += look_for_x_formation(
					&grid,
					row = i,
					col = j,
					top_left_char = cell,
				)
			}
		}
	}
	return x_formations_found
}

main :: proc() {
	input := util.read_input_file("d04/d04.txt")
	// input := util.read_input_file("d04/sample-input.txt")
	xmas_occurrences := part_1(input)
	fmt.println("Part 1:", xmas_occurrences)
	x_formations := part_2(input)
	fmt.println("Part 2:", x_formations)
}

@(test)
test_find_grid_dimensions :: proc(t: ^testing.T) {
	input := "ABC\nDEF\nGHI\nJKL"
	rows, cols := find_grid_dimensions(input)
	testing.expect_value(t, rows, 4)
	testing.expect_value(t, cols, 3)
}

@(test)
test_grid :: proc(t: ^testing.T) {
	g := grid_new(2, 3)
	g.cells[0][0] = 'A'
	g.cells[0][1] = 'B'
	g.cells[0][2] = 'C'
	g.cells[1][0] = 'D'
	g.cells[1][1] = 'E'
	g.cells[1][2] = 'F'
	grid_del(&g)
	testing.expect_value(t, g.rows, 0)
	testing.expect_value(t, g.cols, 0)
}

@(test)
test_make_grid_from_input :: proc(t: ^testing.T) {
	input := "ABCDE\nFGHIJ"
	grid := make_grid_from_input(input)
	defer grid_del(&grid)
	testing.expect_value(t, grid.rows, 2)
	testing.expect_value(t, grid.cols, 5)
	testing.expect_value(t, grid.cells[1][1], 'G')
}

