package main

// Solution for Advent of Code 2025 - Day 9 (https://adventofcode.com/2025/day/9)

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
    tsc_freq, freq_ok := time.tsc_frequency()
    tsc_elapsed := time.read_cycle_counter()
    path_to_lights_state_sum, path_to_counters_state_sum, parse_success := turn_on_machines(input_data_s)
    tsc_elapsed = time.read_cycle_counter() - tsc_elapsed
    fmt.printfln("Took %.5f ms", (f64(tsc_elapsed) / f64(tsc_freq)) * 1000)
    if !parse_success
    {
	fmt.printfln("Error: Failed to parse input file.")
	return
    }

    fmt.printfln("Sum of shortest solution paths to target lights state: %d", path_to_lights_state_sum)
    fmt.printfln("Sum of shortest solution paths to target counters state: %d", path_to_counters_state_sum)
    fmt.printfln("Press any key to exit...")
    tmp_buf: [1]u8
    os.read(os.stdin, tmp_buf[:]) 
}

CountersState :: [16]i16
BinaryState :: bit_set[0..<16; u16]
MachineState :: struct
{
    lights_count: u16,
    button_count: u16,
    buttons: [16]BinaryState,
    target_lights_state: BinaryState,
    target_counters_state: CountersState
}

turn_on_machines :: proc(input: string) -> (path_to_lights_state_sum: uint, path_to_counters_state_sum: uint, ok: bool)
{
    path_to_lights_state_sum = 0
    path_to_counters_state_sum = 0

    machines_cap :: 500
    machines: [machines_cap]MachineState = {}
    machines_count: u16 = 0
    max_lights_count: u16 = 0

    read_s: string = input
    line_i: uint = 0
    for line in strings.split_lines_iterator(&read_s)
    {
	machine: ^MachineState = &machines[machines_count]
	read_line_s: string = line
	for field in strings.split_iterator(&read_line_s, " ")
	{
	    read_field_s: string = field
	    first_c: u8 = read_field_s[0]
	    read_field_s = read_field_s[1 : len(read_field_s) - 1]

	    switch first_c
	    {
	    case '[':
		for c, c_index in read_field_s
		{
		    if c == '#' { machine.target_lights_state |= {c_index} }
		    machine.lights_count += 1
		}
		max_lights_count = max(max_lights_count, machine.lights_count)

	    case '(':
		button: ^BinaryState = &machine.buttons[machine.button_count]
		for num_s in strings.split_iterator(&read_field_s, ",")
		{
		    num, parse_num_ok := strconv.parse_int(num_s)
		    button^ |= {num}
		}
		machine.button_count += 1

	    case '{':
		counter_i: uint = 0
		for num_s in strings.split_iterator(&read_field_s, ",")
		{
		    num, parse_num_ok := strconv.parse_int(num_s)
		    machine.target_counters_state[counter_i] = i16(num)
		    counter_i += 1
		}

	    case:
		fmt.printfln("Error: Failed to parse field at line %d.", line_i)
		return path_to_lights_state_sum, path_to_counters_state_sum, false
	    }
	}

	machines_count += 1
    }

    path_to_lights_state_sum = get_sum_of_shortest_path_lengths_to_light_state(machines[0:machines_count])
    path_to_counters_state_sum = get_sum_of_shortest_path_lengths_to_counters_state(machines[0:machines_count], max_lights_count)

    return path_to_lights_state_sum, path_to_counters_state_sum, true
}

// Part 2
get_sum_of_shortest_path_lengths_to_counters_state :: proc(machines: []MachineState, max_counters_count: u16) -> uint
{
    ButtonCombo :: struct
    {
	buttons: BinaryState,
	counters: CountersState,
	press_count: u16
    }

    ComboBucket :: struct
    {
	combos: [256]ButtonCombo,
	count: u16
    }

    press_buttons :: proc(target_counters: CountersState, counters_count: u16, odd_pattern_to_combos_map: map[BinaryState]ComboBucket) -> uint
    {
	big_number :: 1000000
	counters_total: int = 0
	for counter_i in 0 ..< counters_count
	{
	    counter: i16 = target_counters[counter_i]
	    if counter < 0 { return big_number }
	    counters_total += int(counter)
	}
	if counters_total == 0 { return 0 }

	odd_state: BinaryState = counters_state_to_odd_bin_state(counters_count, target_counters)
	if odd_state not_in odd_pattern_to_combos_map { return big_number }

	total: uint = big_number
	bucket, bucket_found := odd_pattern_to_combos_map[odd_state]
	for combo_i in 0 ..< bucket.count
	{
	    combo: ButtonCombo = bucket.combos[combo_i]
	    half_target: CountersState = {}
	    for counter_i in 0 ..< counters_count
	    {
		half_target[counter_i] = (target_counters[counter_i] - combo.counters[counter_i]) / 2
	    }

	    presses: uint = uint(combo.press_count) + 2 * press_buttons(half_target, counters_count, odd_pattern_to_combos_map)
	    total = min(presses, total)
	}

	return total
    }

    sum: uint = 0
    odd_pattern_to_combos_map := make(map[BinaryState]ComboBucket, pow_uint(2, uint(max_counters_count)))
    defer delete(odd_pattern_to_combos_map)

    machine_i: int = 5
    machine: MachineState = machines[machine_i]

    for machine in machines
    {
	button_combo_count: u16 = u16(pow_uint(2, uint(machine.button_count)))
	clear(&odd_pattern_to_combos_map)

	for combo_i in 0 ..< button_combo_count
	{
	    combo: ButtonCombo = {}
	    combo.buttons = transmute(BinaryState)combo_i
	    for button_i in 0 ..< machine.button_count
	    {
		((combo_i >> button_i) & 1 == 1) or_continue

		for counter_i in machine.buttons[button_i] { combo.counters[counter_i] += 1 }
		combo.press_count += 1
	    }
	    odd_pattern: BinaryState = counters_state_to_odd_bin_state(machine.lights_count, combo.counters)
	    if odd_pattern not_in odd_pattern_to_combos_map { odd_pattern_to_combos_map[odd_pattern] = {} }
	    bucket, bucket_found := &odd_pattern_to_combos_map[odd_pattern]
	    bucket.combos[bucket.count] = combo
	    bucket.count += 1
	}

	sum += press_buttons(machine.target_counters_state, machine.lights_count, odd_pattern_to_combos_map)
    }

    return sum
}

// Part 1
get_sum_of_shortest_path_lengths_to_light_state :: proc(machines: []MachineState) -> uint
{
    SearchNode :: struct
    {
	lights_state: BinaryState,
	prev_node: u16,
	button_index: u8,
	depth: u8
    }

    press_buttons :: proc(machine: MachineState, prev_node_i: u16, states_reached: []b8, search_nodes: []SearchNode, search_nodes_count: ^u16) -> (finish_node: ^SearchNode)
    {
	finish_node = nil 
	prev_state: BinaryState = {} 
	depth: u8 = 1
	if prev_node_i < max(u16)
	{
	    prev_state = search_nodes[prev_node_i].lights_state
	    depth = search_nodes[prev_node_i].depth + 1
	}

	for button_i in 0 ..< machine.button_count
	{
	    new_state: BinaryState = prev_state ~ machine.buttons[button_i]
	    (!states_reached[transmute(u16)new_state]) or_continue
	    search_nodes[search_nodes_count^] = { lights_state = new_state, button_index = u8(button_i), depth = depth, prev_node = prev_node_i }
	    search_nodes_count^ += 1
	    states_reached[transmute(u16)new_state] = true
	    if new_state == machine.target_lights_state
	    {
		finish_node = &search_nodes[search_nodes_count^ - 1]
		break
	    }
	}
	return finish_node
    }

    sum: uint = 0
    possible_states_count :: uint(max(u16))
    states_reached: [possible_states_count]b8 = {}
    search_nodes: []SearchNode = make([]SearchNode, possible_states_count)
    defer delete(search_nodes)

    for machine, machine_i in machines
    {
	finish_node: ^SearchNode = nil
	states_reached = {}
	search_nodes_count: u16 = 0

	states_reached[0] = true
	finish_node = press_buttons(machine, max(u16), states_reached[:], search_nodes[:], &search_nodes_count)

	for node_i: u16 = 0; node_i < search_nodes_count && finish_node == nil; node_i += 1
	{
	    finish_node = press_buttons(machine, node_i, states_reached[:], search_nodes[:], &search_nodes_count)
	}

	if finish_node == nil
	{
	    fmt.printfln("Error: Failed to find solution path for machine %d.", machine_i + 1)
	    return 0
	}

	sum += uint(finish_node.depth)
    }

    return sum
}

print_bin_state :: proc(count: u16, state: BinaryState)
{
    fmt.printf("(")
    for light_i in 0 ..< count
    {
	fmt.printf("%c", int(light_i) in state ? '#' : '.')
    }
    fmt.printf(")")
}

print_counters_state :: proc(count: u16, counters_state: CountersState)
{
    fmt.printf("(")
    for counter_i in 0 ..< count
    {
	fmt.printf("%d%c", counters_state[counter_i], counter_i < count - 1 ? ',' : ')')
    }
}

counters_state_to_odd_bin_state :: proc(count: u16, counters_state: CountersState) -> BinaryState
{
    bin_state: BinaryState = {}
    for counter_i in 0 ..< count
    {
	if counters_state[counter_i] % 2 != 0 { bin_state |= { int(counter_i) } }
    }
    return bin_state
}

pow_uint :: proc(base: uint, exp: uint) -> (result: uint)
{
    result = 1
    for i in 0 ..< exp { result *= base }
    return result
}

_print_type_size :: proc($T: typeid)
{
    fmt.printfln("size_of(%v): %d", typeid_of(T), size_of(T))
}
