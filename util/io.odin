package util

import "core:os"

read_input_file :: proc(path: string) -> string {
    data, ok := os.read_entire_file_from_filename(path)
    if !ok {
        panic("Failed to read file")
    }
    return string(data)
}
