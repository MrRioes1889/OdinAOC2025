package main

// Solution for Advent of Code 2025 - Day 5 (https://adventofcode.com/2025/day/5)

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:sort"

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
    fresh_count, total_fresh_id_count, parse_success := get_fresh_ingredient_count(&input_data_s)
    if !parse_success
    {
	fmt.printfln("Error: Failed to parse input file.")
	return
    }

    fmt.printfln("Fresh ingredient id count: %d", fresh_count)
    fmt.printfln("Total fresh ingredient ids available: %d", total_fresh_id_count)
    fmt.printfln("Press any key to exit...")
    tmp_buf: [1]u8
    os.read(os.stdin, tmp_buf[:]) 
}

IngredientIdRange :: struct
{
    min: uint,
    max: uint
}

ingredient_id_range_compare_min :: proc(a: IngredientIdRange, b: IngredientIdRange) -> int
{
    return -int(a.min < b.min) + int(a.min > b.min)
}

get_fresh_ingredient_count :: proc(input: ^string) -> (fresh_count: uint, total_fresh_id_count: uint, ok: bool)
{
    fresh_count = 0
    total_fresh_id_count = 0
    ranges_capacity: int = strings.count(input^, "-")
    ranges := make([]IngredientIdRange, ranges_capacity)
    defer delete(ranges)

    range_count: uint = 0
    read_ptr: ^string = input
    for line_s in strings.split_lines_after_iterator(read_ptr)
    {
	if len(strings.trim_space(line_s)) == 0
	{
	    break
	}

	sep_index: int = strings.index(line_s, "-")
	range: ^IngredientIdRange = &ranges[range_count]
	min, min_ok := strconv.parse_uint(line_s[0:sep_index])
	max, max_ok := strconv.parse_uint(line_s[sep_index+1:])
	range^ = IngredientIdRange{ min = min, max = max }

	range_count += 1
    }

    // NOTE: Aggregating ranges for efficient id checking and calculating total count of ids in range
    sort.quick_sort_proc(ranges, ingredient_id_range_compare_min)
    aggregated_range_count: uint = 0
    current_aggregate_range: IngredientIdRange = ranges[0]
    for range in ranges
    {
	if range.min > current_aggregate_range.max + 1
	{
	    ranges[aggregated_range_count] = current_aggregate_range
	    current_aggregate_range = range
	    aggregated_range_count += 1
	    continue
	}

	current_aggregate_range.max = max(range.max, current_aggregate_range.max)
    }
    ranges[aggregated_range_count] = current_aggregate_range
    aggregated_range_count += 1

    fmt.printfln("Aggregated ranges:")
    for range in ranges[0:aggregated_range_count]
    {
	fmt.printfln("Min: %d Max: %d", range.min, range.max)
	total_fresh_id_count += range.max - range.min + 1
    }
    fmt.printf("\n")

    // NOTE: Checking if ids are in aggregated ranges
    id_count: uint = 0
    for line_s in strings.split_lines_after_iterator(read_ptr)
    {
	id, id_ok := strconv.parse_uint(line_s)
	is_fresh: bool = false
	for range in ranges[0:aggregated_range_count]
	{
	    if id < range.min
	    {
		break
	    }
	    else if id <= range.max
	    {
		is_fresh = true
		break
	    }
	}

	if is_fresh
	{
	    fresh_count += 1
	}

	id_count += 1
    }

    return fresh_count, total_fresh_id_count, true
}
