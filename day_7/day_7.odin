package main

// Solution for Advent of Code 2025 - Day 7 (https://adventofcode.com/2025/day/7)

import "core:fmt"
import "core:os"
import "core:strings"

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
    split_count, paths_count, parse_success := shoot_beam(input_data_s)
    if !parse_success
    {
	fmt.printfln("Error: Failed to parse input file.")
	return
    }

    fmt.printfln("Split count: %d", split_count)
    fmt.printfln("Paths count: %d", paths_count)
    fmt.printfln("Press any key to exit...")
    tmp_buf: [1]u8
    os.read(os.stdin, tmp_buf[:]) 
}

shoot_beam :: proc(input: string) -> (split_count: uint, possible_paths_count: uint, ok: bool)
{
    split_count = 0
    possible_paths_count = 0

    next_row_beams: []b8 = nil
    defer delete(next_row_beams)
    overlapped_beam_counts: []u64 = nil
    defer delete(overlapped_beam_counts)
    width: int = 0

    read_str: string = input
    for line in strings.split_lines_iterator(&read_str)
    {
	trimmed_line: string = strings.trim_right_space(line)
	if next_row_beams == nil
	{
	    width = len(trimmed_line)
	    next_row_beams = make([]b8, width)
	    overlapped_beam_counts = make([]u64, width)
	}

	line_u8: []u8 = transmute([]u8)trimmed_line
	for &c, c_index in line_u8
	{
	    if !next_row_beams[c_index]
	    {
		if c == 'S'
		{
		    next_row_beams[c_index] = true
		    overlapped_beam_counts[c_index] += 1
		}
		continue
	    }

	    switch c
	    {
	    case '.':
		c = '|'
		next_row_beams[c_index] = true
	    case '^':
		if c_index > 0 && (line_u8[c_index - 1] == '.' || line_u8[c_index - 1] == '|')
		{
		    line_u8[c_index - 1] = '|'
		    next_row_beams[c_index - 1] = true
		    overlapped_beam_counts[c_index - 1] += overlapped_beam_counts[c_index]
		}
		if c_index < width - 1 && (line_u8[c_index + 1] == '.' || line_u8[c_index + 1] == '|')
		{
		    line_u8[c_index + 1] = '|'
		    next_row_beams[c_index + 1] = true
		    overlapped_beam_counts[c_index + 1] += overlapped_beam_counts[c_index]
		}
		next_row_beams[c_index] = false
		overlapped_beam_counts[c_index] = 0
		split_count += 1
	    }
	}
    }

    for count in overlapped_beam_counts
    {
	possible_paths_count += uint(count)
    }

    return split_count, possible_paths_count, true
}
