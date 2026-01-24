package main

// Solution for Advent of Code 2025 - Day 4 (https://adventofcode.com/2025/day/4)

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
    immediate_acc_scrolls_count, max_acc_scrolls_count, parse_success := get_accessible_scrolls_count(&input_data_s)
    if !parse_success
    {
	fmt.printfln("Error: Failed to parse input file.")
	return
    }

    fmt.printfln("Count of immediately accessible scrolls: %d", immediate_acc_scrolls_count)
    fmt.printfln("Max count of accessible scrolls after removals: %d", max_acc_scrolls_count)
    fmt.printfln("Press any key to exit...")
    tmp_buf: [1]u8
    os.read(os.stdin, tmp_buf[:]) 
}

// WARNING: Assumes input is well formed (character grid with stable width and height)
get_accessible_scrolls_count :: proc(input: ^string) -> (immediate_count: uint, repeated_max_count: uint, ok: bool)
{
    repeated_max_count = 0
    immediate_count = 0

    input^ = strings.trim_right(input^, "\n")
    // NOTE: Adding a border of implicit empty slots to prevent conditions in the inner inspection loop
    width: int = strings.index(input^, "\n") + 2
    height: int = strings.count(input^, "\n") + 1 + 2 
    if width <= 2 || height <= 2
    {
	return immediate_count, repeated_max_count, false
    }

    slots: [dynamic]b8 = make([dynamic]b8, width * height, width * height)
    defer delete(slots)

    {
	row_i: int = 0
	for row_s in strings.split_lines_iterator(input)
	{
	    for value, col_i in row_s
	    {
		slots[((row_i + 1) * width) + (col_i + 1)] = value == '@'
	    }

	    row_i += 1
	}
    }

    immediate_count = get_accessible_scrolls_count_helper(slots, width, height, false)

    for
    {
	count: uint = get_accessible_scrolls_count_helper(slots, width, height, true)
	if count == 0
	{
	    break;
	}
	repeated_max_count += count
    }

    return immediate_count, repeated_max_count, true
}

get_accessible_scrolls_count_helper :: proc(slots: [dynamic]b8, width: int, height: int, remove: bool) -> (count: uint)
{
    count = 0
    on_remove: b8 = remove ? false : true
    for row_i in 1..<height - 1
    {
	for col_i in 1..<width - 1
	{
	    scroll_in_slot: b8 = slots[(row_i * width) + col_i]
	    if !scroll_in_slot
	    {
		continue
	    }

	    adjacent_scroll_count: u8 = 
		u8(slots[((row_i - 1) * width) + col_i - 1]) +	// Top-Left
		u8(slots[((row_i - 1) * width) + col_i]) +	// Top
		u8(slots[((row_i - 1) * width) + col_i + 1]) +	// Top-Right
		u8(slots[(row_i * width) + col_i - 1]) +	// Left
		u8(slots[(row_i * width) + col_i + 1]) +	// Right
		u8(slots[((row_i + 1) * width) + col_i - 1]) +	// Bottom-Left
		u8(slots[((row_i + 1) * width) + col_i]) +	// Bottom
		u8(slots[((row_i + 1) * width) + col_i + 1])	// Bottom-Right

	    if adjacent_scroll_count < 4
	    {
		count += 1;
		slots[(row_i * width) + col_i] = on_remove
	    }
	}
    }

    return count
}
