package main

// Solution for Advent of Code 2025 - Day 2 (https://adventofcode.com/2025/day/2)

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
    invalid_id_sum_double_pattern, invalid_id_sum_arbitrary_pattern, parse_success := get_invalid_id_sums(&input_data_s)
    if !parse_success
    {
	fmt.printfln("Error: Failed to parse input file.")
	return
    }

    // Part 1
    fmt.printfln("Sum of invalid ids with double pattern in ranges: %d", invalid_id_sum_double_pattern)
    // Part 2
    fmt.printfln("Sum of invalid ids with arbitrary pattern in ranges: %d", invalid_id_sum_arbitrary_pattern)
    fmt.printfln("Press any key to exit...")
    tmp_buf: [1]u8
    os.read(os.stdin, tmp_buf[:]) 
}

is_id_valid_double :: proc(id_s: string) -> bool
{
    length: int = len(id_s)
    if length % 2 != 0
    {
	return true
    }

    half_i: int = length / 2
    return strings.compare(id_s[0:half_i], id_s[half_i:]) != 0
}

is_id_valid_arbitrary :: proc(id_s: string) -> (id_valid: bool)
{
    id_valid = true
    length: int = len(id_s)
    for pat_length in 1..=(length / 2)
    {
	if (length % pat_length != 0)
	{
	    continue
	}

	pat_count: int = length / pat_length
	full_match: bool = true
	for pat_i in 1..<pat_count
	{
	    pat_offset: int = pat_length * pat_i
	    if strings.compare(id_s[0:pat_length], id_s[pat_offset:pat_offset + pat_length]) != 0
	    {
		full_match = false
		break
	    }
	}

	if (full_match)
	{
	    id_valid = false
	    break
	}
    }

    return id_valid
}

get_invalid_id_sums :: proc(input: ^string) -> (sum_double_pattern: uint, sum_arbitrary_pattern: uint, ok: bool)
{
    sum_double_pattern = 0
    sum_arbitrary_pattern = 0

    id_range_index: uint = 0
    for id_range in strings.split_iterator(input, ",")
    {
	sep_index: int = strings.index(id_range, "-")
	if (sep_index < 0)
	{
	    fmt.printfln("Error: Could not parse id range %d.", id_range_index + 1)
	    return 0, 0, false
	}

	min, min_ok := strconv.parse_uint(id_range[0:sep_index])
	max, max_ok := strconv.parse_uint(id_range[sep_index + 1:])
	if (!min_ok || !max_ok)
	{
	    fmt.printfln("Error: Could not parse id range %d.", id_range_index + 1)
	    return 0, 0, false
	}
	
	fmt.printfln("Min: %d  Max: %d", min, max)
	fmt.printf("Invalid IDs (arbitrary pattern): ")
	for id in min..=max
	{
	    id_s_buf: [32]byte = {}
	    id_s: string = strconv.write_uint(id_s_buf[:], u64(id), 10)

	    id_valid_double: bool = is_id_valid_double(id_s)
	    id_valid_arbitrary: bool = is_id_valid_arbitrary(id_s)

	    sum_double_pattern += !id_valid_double ? id : 0
	    if !id_valid_arbitrary
	    {
		sum_arbitrary_pattern += id
		fmt.printf("%d, ", id)
	    }
	}
	fmt.printf("\n")

	id_range_index += 1
    }

    return sum_double_pattern, sum_arbitrary_pattern, true
}
