package main

// Solution for Advent of Code 2025 - Day 12 (https://adventofcode.com/2025/day/12)

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:time"

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
    tsc_freq, freq_ok := time.tsc_frequency(500 * time.Millisecond)
    tsc_elapsed := time.read_cycle_counter()
    valid_christmas_tree_count, parse_success := test_target_areas(input_data_s)
    tsc_elapsed = time.read_cycle_counter() - tsc_elapsed
    fmt.printfln("Took %.5f ms", (f64(tsc_elapsed) / f64(tsc_freq)) * 1000)
    if !parse_success
    {
	fmt.printfln("Error: Failed to parse input file.")
	return
    }

    fmt.printfln("Valid christmas tree count: %d", valid_christmas_tree_count)
    fmt.printfln("Press any key to exit...")
    tmp_buf: [1]u8
    os.read(os.stdin, tmp_buf[:]) 
}

Present :: struct
{
    shape: matrix[3, 3]u8,
    area_size: u8
}
presents_cap :: 8

TargetArea :: struct
{
    width, height: u8,
    present_counts: [presents_cap]u8
}

test_target_areas :: proc(input: string) -> (valid_count: uint, ok: bool)
{
    valid_count = 0

    presents: [presents_cap]Present = {}
    presents_count: uint = 0

    target_areas_cap :: 1000
    target_areas: [target_areas_cap]TargetArea
    target_areas_count: uint = 0

    read_input_s: string = input
    for line in strings.split_lines_iterator(&read_input_s)
    {
	strings.contains(line, ":") or_continue

	if !strings.contains(line, "x")
	{
	    present: ^Present = &presents[presents_count]
	    for row_i in 0 ..< 3
	    {
		row_line_s, _ := strings.split_lines_iterator(&read_input_s)
		present.shape[row_i, 0] = u8(row_line_s[0] == '#')
		present.shape[row_i, 1] = u8(row_line_s[1] == '#')
		present.shape[row_i, 2] = u8(row_line_s[2] == '#')
		present.area_size += present.shape[row_i, 0] + present.shape[row_i, 1] + present.shape[row_i, 2]
	    }
	    presents_count += 1
	    continue
	}

	target_area: ^TargetArea = &target_areas[target_areas_count]
	read_line_s: string = line

	dimensions_s, _ := strings.split_iterator(&read_line_s, " ")
	width_s, _ := strings.split_iterator(&dimensions_s, "x")
	width, _ := strconv.parse_uint(width_s)
	height_s, _ := strings.split_iterator(&dimensions_s, "x")
	height, _ := strconv.parse_uint(height_s)
	target_area.width = u8(width)
	target_area.height = u8(height)

	present_i: u8 = 0
	for count_s in strings.split_iterator(&read_line_s, " ")
	{
	    count, _ := strconv.parse_uint(count_s)
	    target_area.present_counts[present_i] = u8(count) 
	    present_i += 1
	}

	target_areas_count += 1
    }

    for area in target_areas[0:target_areas_count]
    {
	target_area_size: uint = uint(area.width) * uint(area.height)
	min_required_size: uint = 0
	for present_i in 0 ..< presents_count
	{
	    min_required_size += uint(presents[present_i].area_size) * uint(area.present_counts[present_i])
	}
	if target_area_size >= min_required_size { valid_count += 1 }
    }

    return valid_count, true
}

_print_type_size :: proc($T: typeid)
{
    fmt.printfln("size_of(%v): %d", typeid_of(T), size_of(T))
}
