package main

// Solution for Advent of Code 2025 - Day 6 (https://adventofcode.com/2025/day/6)

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
    sum_by_row, sum_by_column, parse_success := get_summed_results(input_data_s)
    if !parse_success
    {
	fmt.printfln("Error: Failed to parse input file.")
	return
    }

    fmt.printfln("Sum by row: %d", sum_by_row)
    fmt.printfln("Sum by column: %d", sum_by_column)
    fmt.printfln("Press any key to exit...")
    tmp_buf: [1]u8
    os.read(os.stdin, tmp_buf[:]) 
}

ArithmeticOp :: enum u32
{
    add,
    mult
}

calc_value_count :: 4
Calc :: struct
{
    op: ArithmeticOp,
    values: [calc_value_count]u32
}

get_summed_results :: proc(input: string) -> (sum_by_row: uint, sum_by_column: uint, ok: bool)
{
    sum_by_row = 0
    sum_by_column = 0

    calcs := make([]Calc, 1024)

    read_s: string = input
    row_calc_count, _ := parse_calcs_by_row(&read_s, calcs[:])

    fmt.printfln("Calcs by row:")
    sum_by_row = do_calcs_and_sum(calcs[0:row_calc_count])

    for &calc in calcs[0:row_calc_count]
    {
	calc = Calc{}
    }

    read_s = input
    column_calc_count, _ := parse_calcs_by_column(&read_s, calcs[:])

    fmt.printfln("Calcs by column:")
    sum_by_column = do_calcs_and_sum(calcs[0:column_calc_count])

    return sum_by_row, sum_by_column, true
}

// Part 2
parse_calcs_by_column :: proc(input: ^string, calcs_buf: []Calc) -> (calc_count: uint, ok: bool)
{
    calc_count = 0

    lines: [calc_value_count + 1]string = {}
    line_count: uint = 0
    for line in strings.split_lines_after_iterator(input)
    {
	lines[line_count] = line
	line_count += 1
    }

    calc_i: uint = max(uint)
    value_i: uint = 0
    for c, c_index in lines[calc_value_count]
    {
	switch c
	{
	case '+':
	    calc_i += 1
	    calcs_buf[calc_i].op = ArithmeticOp.add
	case '*':
	    calc_i += 1
	    calcs_buf[calc_i].op = ArithmeticOp.mult
	}

	value: uint = 0
	for line_i in 0..<calc_value_count
	{
	    digit: uint = uint(lines[line_i][c_index]) - uint('0')
	    if digit > 0 && digit <= 9
	    {
		value = value * 10 + digit
	    }
	}

	if value == 0
	{
	    value_i = 0
	    continue
	}

	calcs_buf[calc_i].values[value_i] = u32(value)

	value_i += 1
    }
    calc_count = calc_i + 1

    return calc_count, true
}

// Part 1
parse_calcs_by_row :: proc(input: ^string, calcs_buf: []Calc) -> (calc_count: uint, ok: bool)
{
    calc_count = 0
    line_i: uint = 0
    for line in strings.split_lines_after_iterator(input)
    {
	calc_i: uint = 0

	line_length: int = len(line)
	for char_i: int = 0; char_i < line_length; char_i += 1
	{
	    c: u8 = line[char_i]
	    switch c
	    {
	    case '0'..='9':
		value_s_length: int = 0
		value, parse_ok := strconv.parse_uint(s = line[char_i:], n = &value_s_length)
		calcs_buf[calc_i].values[line_i] = u32(value)
		char_i += value_s_length - 1
	    case '+':
		calcs_buf[calc_i].op = ArithmeticOp.add
	    case '*':
		calcs_buf[calc_i].op = ArithmeticOp.mult
	    case:
		continue
	    }

	    calc_i += 1
	}

	calc_count = calc_i
	line_i += 1
    }

    return calc_count, true
}

do_calcs_and_sum :: proc(calcs: []Calc) -> (sum: uint)
{
    sum = 0
    for calc in calcs
    {
	op_sign: u8 = calc.op == ArithmeticOp.mult ? '*' : '+'
	start_value_i: int = 0
	for value, value_i in calc.values
	{
	    if value != 0
	    {
		start_value_i = value_i
		break
	    }
	}

	result: uint = uint(calc.values[start_value_i])
	fmt.printf("%d", result)

	for value_i in start_value_i + 1 ..< calc_value_count
	{
	    value: uint = uint(calc.values[value_i])
	    if value == 0
	    {
		continue
	    }

	    switch calc.op
	    {
	    case .add:
		result += value
	    case .mult:
		result *= value
	    }

	    fmt.printf(" %c %d", op_sign, value)
	}
	fmt.printf(" = %d\n", result)
	sum += result
    }
    return sum
}
