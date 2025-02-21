package d03

import "../util"
import "core:fmt"
import "core:testing"

MulInstruction :: struct {
	op1: int,
	op2: int,
}

evaluate_mul_instruction :: proc(mul_instruction: MulInstruction) -> int {
	return mul_instruction.op1 * mul_instruction.op2
}

parse_mul_instruction :: proc(scanner: ^util.Scanner) -> Maybe(MulInstruction) {
	nil_resetting_scanner :: proc(scanner: ^util.Scanner, pos: int) -> Maybe(MulInstruction) {
		scanner.pos = pos
		return nil
	}
	initial_pos := scanner.pos

	if util.read_n_chars(scanner, 3) != "mul" do return nil_resetting_scanner(scanner, initial_pos)
	if util.read_char(scanner) != '(' do return nil_resetting_scanner(scanner, initial_pos)

	op1, op2: Maybe(int)
	op1 = util.read_int(scanner)
	if op1 == nil do return nil_resetting_scanner(scanner, initial_pos)

	if util.read_char(scanner) != ',' do return nil_resetting_scanner(scanner, initial_pos)

	op2 = util.read_int(scanner)
	if op2 == nil do return nil_resetting_scanner(scanner, initial_pos)

	if util.read_char(scanner) != ')' do return nil_resetting_scanner(scanner, initial_pos)
	return MulInstruction{op1.(int), op2.(int)}
}

part_1 :: proc(input: string) -> int {
	scanner := util.Scanner{input, 0}
	sum_of_muls := 0
	for scanner.pos < len(scanner.input) {
		mul := parse_mul_instruction(&scanner)
		if mul == nil {
			scanner.pos += 1
			continue
		}
		sum_of_muls += evaluate_mul_instruction(mul.(MulInstruction))
	}
	return sum_of_muls
}

part_2 :: proc(input: string) -> int {
	scanner := util.Scanner{input, 0}
	sum_of_muls := 0
	skip := false
	for scanner.pos < len(scanner.input) {
		if !skip && util.read_n_chars(&scanner, 3, peek_only = true) == "mul" {
			mul := parse_mul_instruction(&scanner)
			if mul != nil {
				sum_of_muls += evaluate_mul_instruction(mul.(MulInstruction))
			} else {
				scanner.pos += 3
			}
			continue
		}
		if util.read_n_chars(&scanner, 7, peek_only = true) == "don't()" {
			scanner.pos += 7
			skip = true
			continue
		}
		if util.read_n_chars(&scanner, 4, peek_only = true) == "do()" {
			scanner.pos += 4
			skip = false
			continue
		}
		scanner.pos += 1
	}
	return sum_of_muls
}

main :: proc() {
	input := util.read_input_file("d03/d03.txt")
	// input := util.read_input_file("d03/sample-input.txt")
	sum_of_uncorrupted_mul_instructions := part_1(input)
	fmt.println("Part 1:", sum_of_uncorrupted_mul_instructions)
	sum_of_unskipped_uncorrupted_mul_instructions := part_2(input)
	fmt.println("Part 2:", sum_of_unskipped_uncorrupted_mul_instructions)
}

@(test)
test_parse_mul_instruction :: proc(t: ^testing.T) {
	scanner := util.Scanner{"mul(10,15)abcdef", 0}
	mul := parse_mul_instruction(&scanner)
	testing.expect_value(t, mul, MulInstruction{10, 15})
	testing.expect_value(t, scanner.pos, 10)

	scanner = util.Scanner{"abcdef", 0}
	mul = parse_mul_instruction(&scanner)
	testing.expect_value(t, mul, nil)
	testing.expect_value(t, scanner.pos, 0)
}

@(test)
test_evaluate_mul_instruction :: proc(t: ^testing.T) {
	mul_instruction := MulInstruction{4, 16}
	res := evaluate_mul_instruction(mul_instruction)
	testing.expect_value(t, res, 64)
}

@(test)
test_part_1 :: proc(t: ^testing.T) {
	input := "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))"
	res := part_1(input)
	testing.expect_value(t, res, 161)
}

