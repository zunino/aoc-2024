#+feature dynamic-literals

package d07

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"

import "../util"

Equation :: struct {
	result:   int,
	operands: [dynamic]int,
}

Node :: struct {
	value:      int,
	total:      int,
	plus_child: ^Node,
	mult_child: ^Node,
}

@(private)
parse_equations :: proc(data: string) -> [dynamic]Equation {
	contents := data
	equations: [dynamic]Equation
	for line in strings.split_lines_iterator(&contents) {
		trimmed := strings.trim_space(line)
		result: int
		operands: [dynamic]int
		parts := strings.split(line, ":")
		defer delete(parts)
		result, _ = strconv.parse_int(parts[0])
		values_str := strings.split(strings.trim_space(parts[1]), " ")
		defer delete(values_str)
		for value_str in values_str {
			value, _ := strconv.parse_int(value_str)
			append(&operands, value)
		}
		append(&equations, Equation{result, operands})
	}
	return equations
}

@(private)
read_equations_from_file :: proc(path: string) -> [dynamic]Equation {
	contents := util.read_input_file(path)
	defer delete(contents)
	return parse_equations(contents)
}

@(private)
free_equations :: proc(equations: [dynamic]Equation) {
	for equation in equations {
		delete(equation.operands)
	}
	delete(equations)
}

@(private)
free_tree :: proc(node: ^Node) {
	if node.plus_child != nil do free_tree(node.plus_child)
	if node.mult_child != nil do free_tree(node.mult_child)
	free(node)
}

@(private)
build_tree :: proc(parent: ^Node, operands: []int) {
	if len(operands) == 0 do return
	operand := operands[0]
	plus_child := new(Node)
	plus_child.value = operand
	plus_child.total = parent.total + operand
	mult_child := new(Node)
	mult_child.value = operand
	mult_child.total = parent.total * operand
	parent.plus_child = plus_child
	parent.mult_child = mult_child
	build_tree(plus_child, operands[1:])
	build_tree(mult_child, operands[1:])
}

@(private)
dfs_check_result :: proc(node: ^Node, target: int) -> bool {
	if node.total == target do return true
	if node.plus_child == nil do return false
	return dfs_check_result(node.plus_child, target) || dfs_check_result(node.mult_child, target)
}

@(private)
check_equation :: proc(equation: Equation) -> bool {
	tree := new(Node)
	defer free_tree(tree)
	tree.value = equation.operands[0]
	tree.total = tree.value
	build_tree(tree, equation.operands[1:])
	return dfs_check_result(tree, equation.result)
}

@(private)
part_1 :: proc(equations: [dynamic]Equation) -> int {
	total_calibration_result := 0
	for equation in equations {
		if check_equation(equation) {
			total_calibration_result += equation.result
		}
	}
	return total_calibration_result
}

@(private)
part_2 :: proc() -> int {
	return 0
}

main :: proc() {
	equations_path := "d07/d07.txt"
	if len(os.args) == 2 && os.args[1] == "sample" {
		equations_path = "d07/sample-input.txt"
	}

	equations := read_equations_from_file(equations_path)
	defer free_equations(equations)

	total_calibration_result := part_1(equations)
	fmt.println("Part 1:", total_calibration_result)
}

@(test)
test_parse_equations :: proc(t: ^testing.T) {
	input := "15: 10 5\n" + "240: 6 4 10\n" + "1508: 1500 10 8"
	equations := parse_equations(input)
	defer free_equations(equations)
	testing.expect_value(t, len(equations), 3)
	testing.expect_value(t, equations[0].result, 15)
	testing.expect_value(t, slice.equal(equations[0].operands[:], []int{10, 5}), true)
	testing.expect_value(t, equations[1].result, 240)
	testing.expect_value(t, slice.equal(equations[1].operands[:], []int{6, 4, 10}), true)
	testing.expect_value(t, equations[2].result, 1508)
	testing.expect_value(t, slice.equal(equations[2].operands[:], []int{1500, 10, 8}), true)
}

@(test)
test_build_tree :: proc(t: ^testing.T) {
	operands := [3]int{10, 20, 30}
	tree := new(Node)
	defer free_tree(tree)
	tree.value = operands[0]
	tree.total = tree.value
	build_tree(tree, operands[1:])
	testing.expect(t, tree.plus_child != nil)
	testing.expect_value(t, tree.plus_child.value, 20)
	testing.expect_value(t, tree.plus_child.total, 30)
	testing.expect_value(t, tree.mult_child.value, 20)
	testing.expect_value(t, tree.mult_child.total, 200)
}
