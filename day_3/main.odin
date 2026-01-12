package main

// Solution for Advent of Code 2025 - Day 3 (https://adventofcode.com/2025/day/3)

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
    max_joltage_sum_2, max_joltage_sum_12, parse_success := get_max_joltage_sums(&input_data_s)
    if !parse_success
    {
	fmt.printfln("Error: Failed to parse input file.")
	return
    }

    fmt.printfln("Sum of max battery bank joltages (2_batteries): %d", max_joltage_sum_2)
    fmt.printfln("Sum of max battery bank joltages (12_batteries): %d", max_joltage_sum_12)
    fmt.printfln("Press any key to exit...")
    tmp_buf: [1]u8
    os.read(os.stdin, tmp_buf[:]) 
}

get_battery_bank_max_joltage :: proc(battery_bank_s: string, max_battery_count: uint) -> (max_joltage: uint, parse_success: bool)
{
    max_joltage = 0
    bank_length: uint = len(battery_bank_s)
    if max_battery_count > bank_length
    {
	return max_joltage, false
    }

    next_battery_offset: uint = 0
    for battery_i in 0..<max_battery_count
    {
	max_battery_value: uint = 0
	relative_battery_offset: uint = 0
	for battery_value_s, s_index in battery_bank_s[next_battery_offset : bank_length - uint(max_battery_count - battery_i) + 1]
	{
	    battery_value: uint = uint(battery_value_s - '0') 
	    if (battery_value > 9)
	    {
		return max_joltage, false
	    }

	    if battery_value > max_battery_value
	    {
		max_battery_value = battery_value
		relative_battery_offset = uint(s_index)
	    }
	}

	next_battery_offset += relative_battery_offset + 1
	max_joltage = (max_joltage * 10) + max_battery_value
    }

    return max_joltage, true
}

get_max_joltage_sums :: proc(input: ^string) -> (joltage_sum_2: uint, joltage_sum_12: uint, ok: bool)
{
    joltage_sum_2 = 0
    joltage_sum_12 = 0

    line_i: uint = 1
    for battery_bank_s in strings.split_lines_iterator(input)
    {
	fmt.printfln("Battery bank: %s", battery_bank_s)
	max_bank_joltage_2, ok_2 := get_battery_bank_max_joltage(battery_bank_s, 2)
	max_bank_joltage_12, ok_12 := get_battery_bank_max_joltage(battery_bank_s, 12)

	if !ok_2 || !ok_12
	{
	    fmt.printfln("Error: Failed to parse battery bank at line %d.", line_i)
	    return 0, 0, false
	}

	joltage_sum_2 += max_bank_joltage_2
	joltage_sum_12 += max_bank_joltage_12
	fmt.printfln("Max bank joltage (12 batteries): %d", max_bank_joltage_12)

	line_i += 1
    }

    return joltage_sum_2, joltage_sum_12, true
}
