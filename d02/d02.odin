package d02

import "../util"
import "core:fmt"
import "core:math"
import "core:slice"
import "core:strconv"
import "core:strings"

MIN_DIFF :: 1
MAX_DIFF :: 3

@(private)
parse_reports :: proc(input: ^string) -> [][dynamic]int {
	reports: [dynamic][dynamic]int
	for line in strings.split_lines_iterator(input) {
		str_ids := strings.split(line, " ")
		report: [dynamic]int
		for str_id in str_ids {
			level, _ := strconv.parse_int(str_id)
			append(&report, level)
		}
		append(&reports, report)
	}
	return reports[:]
}

@(private)
check_diff :: proc(v1, v2: int) -> (int, bool) {
	diff := v2 - v1
	return diff, math.abs(diff) >= MIN_DIFF && math.abs(diff) <= MAX_DIFF
}

@(private)
check_report :: proc(report: []int) -> bool {
	diff, _ := check_diff(report[0], report[1])
	increasing := diff > 0
	curr_level := report[0]
	is_safe := true
	for i := 1; i < len(report); i += 1 {
		next_level := report[i]
		_, valid := check_diff(curr_level, next_level)
		if !valid {
			is_safe = false
			break
		}
		if increasing && next_level < curr_level {
			is_safe = false
			break
		}
		if !increasing && next_level > curr_level {
			is_safe = false
			break
		}
		curr_level = next_level
	}
	return is_safe
}

part_1 :: proc(reports: [][dynamic]int) -> int {
	safe_count := 0
	for report in reports {
		if check_report(report[:]) {
			safe_count += 1
		}
	}
	return safe_count
}

part_2 :: proc(reports: [][dynamic]int) -> int {
	safe_count := 0
	for report in reports {
		for i in 0 ..< len(report) {
			subreport: [dynamic]int
			defer delete(subreport)
			append(&subreport, ..report[:i])
			append(&subreport, ..report[i + 1:])
			if check_report(subreport[:]) {
				safe_count += 1
				break
			}
		}
	}
	return safe_count
}

main :: proc() {
	input := util.read_input_file("d02/d02.txt")
	// input := util.read_input_file("d02/sample-input.txt")
	reports := parse_reports(&input)
	defer delete(reports)
	safe_report_count := part_1(reports)
	fmt.println("Part 1:", safe_report_count)
	lenient_safe_report_count := part_2(reports)
	fmt.println("Part 2:", lenient_safe_report_count)
}

