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

read_char :: proc(scanner: ^Scanner, peek_only: bool = false) -> Maybe(u8) {
	if scanner.pos >= len(scanner.input) {
		return nil
	}
	c := scanner.input[scanner.pos]
    if !peek_only {
	    scanner.pos += 1
    }
	return c
}

read_n_chars :: proc(scanner: ^Scanner, n: int, peek_only: bool = false) -> Maybe(string) {
	if scanner.pos + n >= len(scanner.input) {
		return nil
	}
	cs := scanner.input[scanner.pos:scanner.pos + n]
    if !peek_only {
        scanner.pos += n
    }
	return cs
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

    if read_n_chars(scanner, 3) != "mul" do return nil_resetting_scanner(scanner, initial_pos)
	if read_char(scanner) != '(' do return nil_resetting_scanner(scanner, initial_pos)

	op1, op2: Maybe(int)
	op1 = read_int(scanner)
	if op1 == nil do return nil_resetting_scanner(scanner, initial_pos)

    if read_char(scanner) != ',' do return nil_resetting_scanner(scanner, initial_pos)

	op2 = read_int(scanner)
	if op2 == nil do return nil_resetting_scanner(scanner, initial_pos)

	if read_char(scanner) != ')' do return nil_resetting_scanner(scanner, initial_pos)
	return MulInstruction{op1.(int), op2.(int)}
}

part_1 :: proc(input: string) -> int {
	scanner := Scanner{input, 0}
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
	scanner := Scanner{input, 0}
	sum_of_muls := 0
	skip := false
	for scanner.pos < len(scanner.input) {
        if !skip && read_n_chars(&scanner, 3, peek_only=true) == "mul" {
            mul := parse_mul_instruction(&scanner)
            if mul != nil {
		        sum_of_muls += evaluate_mul_instruction(mul.(MulInstruction))
            } else {
                scanner.pos += 3
            }
            continue
        }
        if read_n_chars(&scanner, 7, peek_only=true) == "don't()" {
            scanner.pos += 7
            skip = true
            continue
        }
        if read_n_chars(&scanner, 4, peek_only=true) == "do()" {
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

