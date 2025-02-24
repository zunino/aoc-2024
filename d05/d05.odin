#+feature dynamic-literals

package d05

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"

Predecessors :: map[int][dynamic]int // values that must occur before n
Successors :: map[int][dynamic]int // values that must occur after n
Pages :: [dynamic]int

@(private)
parse_input_file :: proc(path: string) -> (Predecessors, Successors, [dynamic]Pages) {
	data, ok := os.read_entire_file_from_filename(path)
	if !ok {
		panic("Failed to read file")
	}
	defer delete(data)
	contents := string(data)
	predecessors := make(map[int][dynamic]int)
	successors := make(map[int][dynamic]int)
	updates: [dynamic]Pages
	section := 1
	for line in strings.split_lines_iterator(&contents) {
		trimmed := strings.trim_space(line)
		if section == 1 {
			if len(trimmed) == 0 {
				section = 2
				continue
			}
			values_str := strings.split(line, "|")
			defer delete(values_str)
			v1, _ := strconv.parse_int(values_str[0])
			v2, _ := strconv.parse_int(values_str[1])
			if !(v2 in predecessors) {
				predecessors[v2] = [dynamic]int{}
			}
			if !(v1 in successors) {
				successors[v1] = [dynamic]int{}
			}
			append(&predecessors[v2], v1)
			append(&successors[v1], v2)
		} else {
			values_str := strings.split(line, ",")
			defer delete(values_str)
			pages: Pages
			for v_str in values_str {
				v, _ := strconv.parse_int(v_str)
				append(&pages, v)
			}
			append(&updates, pages)
		}
	}
	return predecessors, successors, updates
}

@(private)
delete_map :: proc(m: map[int][dynamic]int) {
	for _, &v in m {
		delete(v)
	}
	delete(m)
}

@(private)
delete_dynarr_of_dynarr :: proc(da: [dynamic][dynamic]int) {
	for &elem in da {
		delete(elem)
	}
	delete(da)
}

@(private)
check_page_order :: proc(
	successors: Successors,
	predecessors: Predecessors,
	pages: Pages,
) -> bool {
	for page, i in pages {
		page_predecessors := predecessors[page][:]
		page_successors := successors[page][:]
		for n in 0 ..< i {
			if !slice.contains(page_predecessors, pages[n]) {
				return false
			}
		}
		for n in i + 1 ..< len(pages) {
			if !slice.contains(page_successors, pages[n]) {
				return false
			}
		}
	}
	return true
}

@(private)
part_1 :: proc(successors: Successors, predecessors: Predecessors, updates: []Pages) -> int {
	middle_page_numbers_sum := 0
	for pages in updates {
		if !check_page_order(successors, predecessors, pages) do continue
		middle_page_numbers_sum += pages[len(pages) / 2]
	}
	return middle_page_numbers_sum
}

fix_page_ordering :: proc(successors: Successors, predecessors: Predecessors, pages: ^Pages) {
	for {
		swaps := false
		for i in 0 ..< len(pages) - 1 {
			curr_page := pages[i]
			next_page := pages[i + 1]
			page_successors := successors[curr_page][:]
			if slice.contains(page_successors, next_page) do continue
			slice.swap(pages[:], i, i + 1)
			swaps = true
		}
		if !swaps do break
	}
}

@(private)
part_2 :: proc(successors: Successors, predecessors: Predecessors, updates: []Pages) -> int {
	middle_page_numbers_sum := 0
	for &pages in updates {
		if check_page_order(successors, predecessors, pages) do continue
		fix_page_ordering(successors, predecessors, &pages)
		middle_page_numbers_sum += pages[len(pages) / 2]
	}
	return middle_page_numbers_sum
}

main :: proc() {
	predecessors, successors, list_of_updates := parse_input_file("d05/d05.txt")
	// predecessors, successors, list_of_updates := parse_input_file("d05/sample-input.txt")
	defer delete_dynarr_of_dynarr(list_of_updates)
	defer delete_map(successors)
	defer delete_map(predecessors)
	middle_page_sum_correct_updates := part_1(successors, predecessors, list_of_updates[:])
	fmt.println("Part 1:", middle_page_sum_correct_updates)
	middle_page_sum_incorrect_updates := part_2(successors, predecessors, list_of_updates[:])
	fmt.println("Part 2:", middle_page_sum_incorrect_updates)
}

@(test)
test_check_page_order :: proc(t: ^testing.T) {
	successors := Successors {
		10 = [dynamic]int{20, 30, 70},
		20 = [dynamic]int{30, 70},
		30 = [dynamic]int{70},
		70 = [dynamic]int{},
	}
	defer delete_map(successors)
	predecessors := Predecessors {
		10 = [dynamic]int{},
		20 = [dynamic]int{10},
		30 = [dynamic]int{10, 20},
		70 = [dynamic]int{10, 20, 30},
	}
	defer delete_map(predecessors)
	updates := [dynamic]Pages{Pages{20, 10, 30}, Pages{10, 70}, Pages{20, 30, 70}, Pages{70, 20}}
	defer delete_dynarr_of_dynarr(updates)
	results: [dynamic]bool
	defer delete(results)
	for update in updates {
		append(&results, check_page_order(successors, predecessors, update))
	}
	testing.expect_value(t, slice.equal(results[:], []bool{false, true, true, false}), true)
}

@(test)
test_fix_page_ordering :: proc(t: ^testing.T) {
	successors := Successors {
		10 = [dynamic]int{20, 30, 70},
		20 = [dynamic]int{30, 70},
		30 = [dynamic]int{70},
		70 = [dynamic]int{},
	}
	defer delete_map(successors)
	predecessors := Predecessors {
		10 = [dynamic]int{},
		20 = [dynamic]int{10},
		30 = [dynamic]int{10, 20},
		70 = [dynamic]int{10, 20, 30},
	}
	defer delete_map(predecessors)
	pages := Pages{30, 70, 10, 20}
	defer delete(pages)
	fixed_pages := Pages{10, 20, 30, 70}
	defer delete(fixed_pages)
	fix_page_ordering(successors, predecessors, &pages)
	testing.expect_value(t, slice.equal(pages[:], fixed_pages[:]), true)
}

