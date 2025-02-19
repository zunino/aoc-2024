package d03

import "../util"
import "core:fmt"
import "core:math"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"

MulInstruction :: struct {
	op1: int,
	op2: int,
}

evaluate_mul_instruction :: proc(mul_instruction: MulInstruction) -> int {
	return mul_instruction.op1 * mul_instruction.op2
}

Scanner :: struct {
	input: string,
	pos:   int,
}

read_char :: proc(scanner: ^Scanner) -> Maybe(u8) {
	if scanner.pos >= len(scanner.input) {
		return nil
	}
	c := scanner.input[scanner.pos]
	scanner.pos += 1
	return c
}

read_n_chars :: proc(scanner: ^Scanner, n: int) -> Maybe(string) {
	if scanner.pos + n >= len(scanner.input) {
		return nil
	}
	cs := scanner.input[scanner.pos:scanner.pos + n]
	scanner.pos += n
	return cs
}

check_expected_sequence :: proc(scanner: ^Scanner, expected_sequence: string) -> bool {
	read_chars := read_n_chars(scanner, len(expected_sequence))
	if read_chars == nil {
		return false
	}
	if read_chars != expected_sequence {
		scanner.pos -= len(expected_sequence)
		return false
	}
	return true
}

read_int :: proc(scanner: ^Scanner) -> Maybe(int) {
	if scanner.pos >= len(scanner.input) {
		return nil
	}
	pos_0 := scanner.pos
	pos_1 := pos_0
	for i in pos_0 ..< len(scanner.input) {
		c := scanner.input[i]
		if c < '0' || c > '9' {
			break
		}
		pos_1 += 1
	}
	if pos_1 == pos_0 {
		return nil
	}
	scanner.pos += pos_1 - pos_0
	int_value, _ := strconv.parse_int(scanner.input[pos_0:pos_1 + 1])
	return int_value
}

parse_mul_instruction :: proc(scanner: ^Scanner) -> Maybe(MulInstruction) {
    nil_resetting_scanner :: proc(scanner: ^Scanner, pos: int) -> Maybe(MulInstruction) {
        scanner.pos = pos
        return nil
    }
    initial_pos := scanner.pos

	if !check_expected_sequence(scanner, "mul") do return nil_resetting_scanner(scanner, initial_pos)
	if read_char(scanner) != '(' do return nil_resetting_scanner(scanner, initial_pos)

	op1, op2: Maybe(int)
	op1 = read_int(scanner)
	if op1 == nil do return nil_resetting_scanner(scanner, initial_pos)

	if !check_expected_sequence(scanner, ",") do return nil_resetting_scanner(scanner, initial_pos)

	op2 = read_int(scanner)
	if op2 == nil do return nil_resetting_scanner(scanner, initial_pos)

	if read_char(scanner) != ')' do return nil_resetting_scanner(scanner, initial_pos)
	return MulInstruction{op1.(int), op2.(int)}
}

parse_mul_instructions :: proc(input: string) -> []MulInstruction {
	mul_instructions: [dynamic]MulInstruction
	scanner := Scanner{input, 0}
	for scanner.pos < len(scanner.input) {
		mul := parse_mul_instruction(&scanner)
		if mul == nil {
			scanner.pos += 1
			continue
		}
		append(&mul_instructions, mul.(MulInstruction))
	}
	return mul_instructions[:]
}

part_1 :: proc(input: string) -> int {
	mul_instructions := parse_mul_instructions(input)
	defer delete(mul_instructions)
	sum_of_muls := 0
	for mul_instruction in mul_instructions {
		sum_of_muls += evaluate_mul_instruction(mul_instruction)
	}
	return sum_of_muls
}

main :: proc() {
	input := util.read_input_file("d03/d03.txt")
	// input := util.read_input_file("d03/sample-input.txt")
	sum_of_uncorrupted_mul_instructions := part_1(input)
	fmt.println("Part 1:", sum_of_uncorrupted_mul_instructions)
}

@(test)
test_read_char :: proc(t: ^testing.T) {
	scanner := Scanner{"abcdef", 0}
	c := read_char(&scanner)
	testing.expect_value(t, c, 'a')
	testing.expect_value(t, scanner.pos, 1)
}

@(test)
test_read_n_chars :: proc(t: ^testing.T) {
	scanner := Scanner{"abcdef", 0}
	cs := read_n_chars(&scanner, 3)
	testing.expect_value(t, cs, "abc")
	testing.expect_value(t, scanner.pos, 3)
}

@(test)
test_read_int :: proc(t: ^testing.T) {
	scanner := Scanner{"123abc", 0}
	v := read_int(&scanner)
	testing.expect_value(t, v, 123)
	testing.expect_value(t, scanner.pos, 3)

	scanner = Scanner{"x123abc", 0}
	v = read_int(&scanner)
	testing.expect_value(t, v, nil)
	testing.expect_value(t, scanner.pos, 0)
}

@(test)
test_check_expected_sequence_ :: proc(t: ^testing.T) {
	scanner := Scanner{"abcdef", 0}
	res := check_expected_sequence(&scanner, "abc")
	testing.expect_value(t, res, true)
	testing.expect_value(t, scanner.pos, 3)

	scanner = Scanner{"abxdef", 0}
	res = check_expected_sequence(&scanner, "abc")
	testing.expect_value(t, res, false)
	testing.expect_value(t, scanner.pos, 0)
}

@(test)
test_parse_mul_instruction :: proc(t: ^testing.T) {
	scanner := Scanner{"mul(10,15)abcdef", 0}
	mul := parse_mul_instruction(&scanner)
	testing.expect_value(t, mul, MulInstruction{10, 15})
	testing.expect_value(t, scanner.pos, 10)

	scanner = Scanner{"abcdef", 0}
	mul = parse_mul_instruction(&scanner)
	testing.expect_value(t, mul, nil)
	testing.expect_value(t, scanner.pos, 0)
}

@(test)
test_parse_mul_instructions :: proc(t: ^testing.T) {
	input := "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))"
	mul_instructions := parse_mul_instructions(input)
	defer delete(mul_instructions)
	testing.expect_value(t, len(mul_instructions), 4)
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

