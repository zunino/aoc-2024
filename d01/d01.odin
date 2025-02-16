package d01

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:slice"
import "core:math"
import "../util"

@(private)
parse_id_lists :: proc(input: ^string) -> ([dynamic]int, [dynamic]int) {
    left, right: [dynamic]int
    for line in strings.split_lines_iterator(input) {
        str_ids := strings.split(line, "   ")
        left_id, _ := strconv.parse_int(str_ids[0])
        right_id, _ := strconv.parse_int(str_ids[1])
        append(&left, left_id)
        append(&right, right_id) 
    }
    return left, right
}

@(private)
compute_sum_of_differences :: proc(left, right: [dynamic]int) -> int {
    sum := 0
    for n := 0; n < len(left); n += 1 {
        sum += math.abs(left[n] - right[n])
    }
    return sum
}

part_1 :: proc(left, right: [dynamic] int) -> int {
    slice.sort(left[:])
    slice.sort(right[:])
    return compute_sum_of_differences(left, right)
}

part_2 :: proc(left, right: [dynamic] int) -> int {
    tally := new([100000]int)
    defer free(tally)
    for n in right {
        tally[n] += 1
    }
    similarity_score: int
    for n in left {
        similarity_score += n * tally[n]
    }
    return similarity_score
}

main :: proc() {
    input := util.read_input_file("d01/d01.txt") 
    left, right := parse_id_lists(&input)
    fmt.println("Part 1:", part_1(left, right))
    fmt.println("Part 2:", part_2(left, right))
}
