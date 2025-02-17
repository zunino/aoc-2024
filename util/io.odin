package util

import "core:os"
import "core:strings"

read_input_file :: proc(path: string) -> string {
    data, ok := os.read_entire_file_from_filename(path)
    if !ok {
        panic("Failed to read file")
    }
    contents := string(data)
    lines: [dynamic]string
    for line in strings.split_lines_iterator(&contents) {
        trimmed := strings.trim_space(line)
        if len(trimmed) == 0 || strings.starts_with(trimmed, "#") {
            continue
        }
        append(&lines, trimmed)
    }
    return strings.join(lines[:], "\n")
}
