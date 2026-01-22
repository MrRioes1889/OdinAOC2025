package main

// Solution for Advent of Code 2025 - Day 11 (https://adventofcode.com/2025/day/11)

import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"
import "core:mem"

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
    you_to_out_path_count, svr_to_out_restricted_path_count, parse_success := get_path_counts(input_data_s)
    tsc_elapsed = time.read_cycle_counter() - tsc_elapsed
    fmt.printfln("Took %.5f ms", (f64(tsc_elapsed) / f64(tsc_freq)) * 1000)
    if !parse_success
    {
	fmt.printfln("Error: Failed to parse input file.")
	return
    }

    fmt.printfln("Path count from 'you' to 'out': %d", you_to_out_path_count)
    fmt.printfln("Path count from 'svr' to 'out' over 'dac' and 'fft': %d", svr_to_out_restricted_path_count)
    fmt.printfln("Press any key to exit...")
    tmp_buf: [1]u8
    os.read(os.stdin, tmp_buf[:]) 
}

NodeIndex :: u16
NodeName :: [4]u8
Node :: struct
{
    name: NodeName,
    children_count: u16,
    branches_offset: u16
}
nodes_cap :: 1000

get_path_counts :: proc(input: string) -> (you_to_out_path_count: uint, svr_to_out_restricted_path_count: uint, ok: bool)
{
    you_to_out_path_count = 0
    svr_to_out_restricted_path_count = 0

    nodes: [nodes_cap]Node = {}
    nodes_count: u16 = 0

    branches_s: [nodes_cap]string = {}
    branches_cap :: nodes_cap * 5
    branches: [branches_cap]NodeIndex = {}
    branches_count: u16 = 0

    name_to_node_index_map := make(map[NodeName]NodeIndex, nodes_cap)
    defer delete(name_to_node_index_map)

    read_input_s: string = input
    for line in strings.split_lines_iterator(&read_input_s)
    {
	read_line_s: string = line
	node: ^Node = &nodes[nodes_count]
	node.name = str_to_name(read_line_s[0:3])
	name_to_node_index_map[node.name] = nodes_count
	branches_s[nodes_count] = read_line_s[5:]
	nodes_count += 1
    }

    node: ^Node = &nodes[nodes_count]
    node.name = str_to_name("out")
    name_to_node_index_map[node.name] = nodes_count
    nodes_count += 1

    you_node_i, you_node_found := name_to_node_index_map[str_to_name("you")]
    out_node_i, out_node_found := name_to_node_index_map[str_to_name("out")]
    svr_node_i, svr_node_found := name_to_node_index_map[str_to_name("svr")]
    dac_node_i, dac_node_found := name_to_node_index_map[str_to_name("dac")]
    fft_node_i, fft_node_found := name_to_node_index_map[str_to_name("fft")]
    if !you_node_found || !out_node_found || !svr_node_found || !dac_node_found || !fft_node_found
    {
	fmt.printfln("Error: Could not find all starting and/or target node. ('you', 'svr', 'dac', 'fft' and 'out')")
	return 0, 0, false
    }

    for &node, node_i in nodes[0:nodes_count]
    {
	node.branches_offset = branches_count
	read_branches_s: string = branches_s[node_i]
	for branch_s in strings.split_iterator(&read_branches_s, " ")
	{
	    child_node_i, child_node_found := name_to_node_index_map[str_to_name(branch_s[0:3])]
	    if !child_node_found
	    {
		fmt.printfln("Error: Could not find child node called '%s' in nodes array on line %d.", branch_s[0:3], node_i + 1)
		return 0, 0, false
	    }
	    node.children_count += 1
	    branches[branches_count] = child_node_i
	    branches_count += 1
	}
    }

    you_to_out_path_count = get_path_count(you_node_i, out_node_i, nodes[0:nodes_count], branches[0:branches_count])
    svr_to_out_restricted_path_count = get_path_count_over_nodes({ svr_node_i, fft_node_i, dac_node_i, out_node_i }, nodes[0:nodes_count], branches[0:branches_count])
    svr_to_out_restricted_path_count += get_path_count_over_nodes({ svr_node_i, dac_node_i, fft_node_i, out_node_i }, nodes[0:nodes_count], branches[0:branches_count])

    return you_to_out_path_count, svr_to_out_restricted_path_count, true
}

get_path_count :: proc(start: NodeIndex, target: NodeIndex, nodes: []Node, branches: []NodeIndex) -> uint
{
    nodes_count: int = len(nodes)
    memoization_cache: [nodes_cap]u64 = {}
    mem.set(&memoization_cache, 0xFF, size_of(memoization_cache[0]) * nodes_count)
    return _get_path_count(start, target, nodes, branches, memoization_cache[0:nodes_count])
}

get_path_count_over_nodes :: proc(path_nodes: []NodeIndex, nodes: []Node, branches: []NodeIndex) -> uint
{
    nodes_count: int = len(nodes)
    memoization_cache: [nodes_cap]u64 = {}
    mem.set(&memoization_cache, 0xFF, size_of(memoization_cache[0]) * nodes_count)

    length: uint = 0
    for path_node_i := len(path_nodes) - 1; path_node_i > 0; path_node_i -= 1
    {
	target_node_i: NodeIndex = path_nodes[path_node_i]
	start_node_i: NodeIndex = path_nodes[path_node_i - 1]
	length = _get_path_count(start_node_i, target_node_i, nodes, branches, memoization_cache[0:nodes_count])
	mem.set(&memoization_cache, 0xFF, size_of(memoization_cache[0]) * nodes_count)
	memoization_cache[start_node_i] = u64(length)
    }

    return length
}

_get_path_count :: proc(start: NodeIndex, target: NodeIndex, nodes: []Node, branches: []NodeIndex, memoization_cache: []u64) -> uint
{
    if memoization_cache[start] != max(u64) { return uint(memoization_cache[start]) }
    if start == target { return 1 }

    node: Node = nodes[start]
    path_count: uint = 0
    for child_i in branches[node.branches_offset : node.branches_offset + node.children_count]
    {
	path_count += _get_path_count(child_i, target, nodes, branches, memoization_cache)
    }

    memoization_cache[start] = u64(path_count)
    return path_count
}

str_to_name :: proc(str: string) -> (arr: NodeName)
{
    length: int = min(len(str), len(arr) - 1)
    for char_i in 0 ..< length
    {
	arr[char_i] = str[char_i]
    }
    arr[length] = 0
    return arr
}

_print_type_size :: proc($T: typeid)
{
    fmt.printfln("size_of(%v): %d", typeid_of(T), size_of(T))
}
