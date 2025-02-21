package util

import "core:strconv"
import "core:testing"

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

