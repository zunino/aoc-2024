package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:slice"
import "core:math"
import "util"

parse_and_sort_id_lists :: proc(input: ^string) -> ([dynamic]int, [dynamic]int) {
    left, right: [dynamic]int
    for line in strings.split_lines_iterator(input) {
        str_ids := strings.split(line, "   ")
        left_id, _ := strconv.parse_int(str_ids[0])
        right_id, _ := strconv.parse_int(str_ids[1])
        append(&left, left_id)
        append(&right, right_id) 
    }
    slice.sort(left[:])
    slice.sort(right[:])
    return left, right
}

compute_sum_of_differences :: proc(left, right: [dynamic]int) -> int {
    sum := 0
    for n := 0; n < len(left); n += 1 {
        sum += math.abs(left[n] - right[n])
    }
    return sum
}

main :: proc() {
    input := util.read_input_file("d01.txt") 
    left, right := parse_and_sort_id_lists(&input)
    fmt.println(compute_sum_of_differences(left, right))
}
