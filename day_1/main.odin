package main

// Solution for Advent of Code 2025 - Day 1 (https://adventofcode.com/2025/day/1)

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

main :: proc()
{
    filename: string = "input.txt"
    if len(os.args) > 1
    {
	filename = os.args[1] 
    }

    input_data, read_success := os.read_entire_file_from_filename(filename)
    if !read_success
    {
	fmt.printfln("Error: Failed to read input file '%s'.", filename)
	return
    }
    defer delete(input_data)

    input_data_s := string(input_data)
    dial_value_offset: int = 50
    fmt.printfln("Starting dial value: %d", dial_value_offset)
    exact_count, transient_count, parse_success := count_dial_zero_hits(dial_value_offset, &input_data_s)
    if !parse_success
    {
	fmt.printfln("Error: Failed to parse input file.")
	return
    }

    fmt.printfln("Exact Zero Dial Hit Count: %d", exact_count)
    fmt.printfln("Transient Zero Dial Hit Count: %d", transient_count)
    fmt.printfln("Press any key to exit...")
    tmp_buf: [1]u8
    os.read(os.stdin, tmp_buf[:]) 
}

// Returns: 
// exact_count: 	counts when the dial landed on zero after a line of execution 
// transient_count: 	counts when the dial touched zero during a line of execution 
count_dial_zero_hits :: proc(dial_value_offset: int, input: ^string) -> (exact_count: uint, transient_count: uint, ok: bool)
{
    dial_range_max :: 100
    exact_count = 0
    transient_count = 0
    dial_value: int = dial_value_offset

    line_index: uint = 0
    for line in strings.split_lines_iterator(input)
    {
	length := len(line)
	if (length < 2)
	{
	    fmt.printfln("Error: Failed to parse line %d", line_index + 1)
	    return exact_count, transient_count, false
	}

	direction: int = 0
	direction += line[0] == 'L' ? -1 : 0
	direction += line[0] == 'R' ? 1 : 0
	dial_clicks, parse_success := strconv.parse_int(line[1:])
	if !parse_success || direction == 0 
	{
	    fmt.printfln("Error: Failed to parse line %d", line_index + 1)
	    return exact_count, transient_count, false
	}

	// NOTE: Inverts the current dial value on left rotation
	effective_dial_offset: int = direction > 0 ? dial_value : ((dial_range_max - dial_value) % dial_range_max)
	transient_count += uint((effective_dial_offset + dial_clicks) / dial_range_max)

	dial_clicks *= direction
	dial_value = (dial_value + dial_clicks) % dial_range_max
	dial_value += dial_value < 0 ? dial_range_max : 0
	exact_count += uint(dial_value == 0)
	fmt.printfln("%s:\tNew Dial Value: %d\tDial On Zero: %t\tTotal exact hits: %d\tTotal transient hits: %d", line, dial_value, dial_value == 0, exact_count, transient_count) 
	
	line_index += 1
    }

    return exact_count, transient_count, true
}
