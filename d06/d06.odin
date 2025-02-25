#+feature dynamic-literals

package d06

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
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

Vec2 :: struct {
	x, y: int,
}

Heading :: enum {
	Up,
	Right,
	Down,
	Left,
}

heading_vectors := [Heading]Vec2 {
	.Up    = {0, -1},
	.Right = {1, 0},
	.Down  = {0, 1},
	.Left  = {-1, 0},
}

right_turn := [Heading]Heading {
	.Up = .Right,
	.Right = .Down,
	.Down = .Left,
	.Left = .Up
}

LabMap :: struct {
	locations:      [dynamic][dynamic]Cell,
	rows, cols: int,
	guard_position: Vec2,
	guard_heading:  Heading,
}

@(private)
parse_lab_map :: proc(path: string) -> LabMap {
	data, ok := os.read_entire_file_from_filename(path)
	if !ok {
		panic("Failed to read file")
	}
	defer delete(data)
	contents := string(data)
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
free_lab_map :: proc(lab_map: ^LabMap) {
	for row in lab_map.locations {
		delete(row)
	}
	delete(lab_map.locations)
}

@(private)
part_1 :: proc(lab_map: LabMap) -> int {
	distinct_positions_visited: int
	pos := lab_map.guard_position
	heading := lab_map.guard_heading
	for pos.x >=0 && pos.x < lab_map.cols && pos.y >= 0 && pos.y < lab_map.rows {
		cell := &lab_map.locations[pos.y][pos.x]
		if cell.type == CellType.Obstacle {
			heading_vec := heading_vectors[heading]
			pos.x -= heading_vec.x
			pos.y -= heading_vec.y
			heading = right_turn[heading]
			continue
		}
		if !cell.visited {
			distinct_positions_visited += 1
			cell.visited = true
		}
		heading_vec := heading_vectors[heading]
		pos.x += heading_vec.x
		pos.y += heading_vec.y
	}
	return distinct_positions_visited
}

@(private)
part_2 :: proc() {
}

main :: proc() {
	// lab_map := parse_lab_map("d06/sample-input.txt")
	lab_map := parse_lab_map("d06/d06.txt")
	defer free_lab_map(&lab_map)
	distinct_positions_visited := part_1(lab_map)
	fmt.println("Part 1:", distinct_positions_visited)
}
