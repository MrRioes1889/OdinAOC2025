package main

// Solution for Advent of Code 2025 - Day 8 (https://adventofcode.com/2025/day/8)

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:math/linalg"
import "core:math"
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
    circuit_3_size_product, last_connection_x_product, parse_success := connect_junctions(input_data_s)
    if !parse_success
    {
	fmt.printfln("Error: Failed to parse input file.")
	return
    }

    fmt.printfln("Product of the sizes of the 3 largest circuits: %d", circuit_3_size_product)
    fmt.printfln("Product of the last connection's x-coordinates: %d", last_connection_x_product)
    fmt.printfln("Press any key to exit...")
    tmp_buf: [1]u8
    os.read(os.stdin, tmp_buf[:]) 
}

Vec3 :: linalg.Vector3f32
BoxId :: u16

JunctionBox :: struct
{
    pos: Vec3,
    next_box: BoxId,
    prev_box: BoxId,
}

BoxDistance :: struct
{
    box_0, box_1: BoxId,
    value: f32
}

Circuit :: struct
{
    start_box: BoxId,
    length: u16
}

connect_junctions :: proc(input: string) -> (circuit_3_size_product: uint, last_connection_x_product: uint, ok: bool)
{
    circuit_3_size_product = 0
    last_connection_x_product = 0

    box_count :: 1000
    boxes: [box_count]JunctionBox = {}

    read_s: string = input
    line_i: uint = 0
    for line in strings.split_lines_iterator(&read_s)
    {
	r_line: string = line
	num_s, ok := strings.split_iterator(&r_line, ",")
	num, parse_ok := strconv.parse_f32(num_s)
	boxes[line_i].pos.x = num
	num_s, ok = strings.split_iterator(&r_line, ",")
	num, parse_ok = strconv.parse_f32(num_s)
	boxes[line_i].pos.y = num
	num_s, ok = strings.split_iterator(&r_line, ",")
	num, parse_ok = strconv.parse_f32(num_s)
	boxes[line_i].pos.z = num

	boxes[line_i].next_box = max(BoxId)
	boxes[line_i].prev_box = max(BoxId)
	line_i += 1
    }

    // NOTE: Calculating a by distance sorted array of all possible box circuit connections
    dist_cap :: box_count * (box_count - 1) / 2
    dists_sq: []BoxDistance = make([]BoxDistance, dist_cap)
    dist_count: uint = 0
    for box_0 in 0 ..< box_count
    {
	for box_1 in box_0 + 1 ..< box_count
	{
	    dist: ^BoxDistance = &dists_sq[dist_count]
	    dist.box_0 = BoxId(box_0)
	    dist.box_1 = BoxId(box_1)
	    dist.value = get_distance_sq(boxes[box_0].pos, boxes[box_1].pos)
	    dist_count += 1
	}
    }
    sort.quick_sort_proc(dists_sq, dist_cmp)

    // NOTE: Making first thousand circuit connections
    for dist, dist_i in dists_sq[0:1000]
    {
	if boxes_share_circuit(boxes[:], dist.box_0, dist.box_1) { continue }

	last_box_0: u16 = get_last_circuit_box(boxes[:], dist.box_0)
	first_box_1: u16 = get_first_circuit_box(boxes[:], dist.box_1)
	boxes[last_box_0].next_box = first_box_1
	boxes[first_box_1].prev_box = last_box_0
    }

    circuits: [box_count]Circuit = {}
    circuit_count: uint = 0
    for box, box_i in boxes
    {
	if box.prev_box != max(BoxId) { continue }
	circuit: ^Circuit = &circuits[circuit_count]
	circuit.start_box = BoxId(box_i)
	circuit.length = get_circuit_length_from_start(boxes[:], BoxId(box_i))
	circuit_count += 1
    }
    sort.quick_sort_proc(circuits[0:circuit_count], circuit_cmp_rev)

    fmt.printfln("Circuits after first 1000 connections")
    #reverse for circuit, circuit_i in circuits[0:circuit_count]
    {
	fmt.printfln("Circuit %d: length = %d", circuit_i, circuit.length)
    }
    fmt.printf("\n")

    // NOTE: Making the remaining circuit connections (Very inefficiently)
    last_conn_box_0, last_conn_box_1: JunctionBox = {}, {}
    for dist, dist_i in dists_sq[1000:]
    {
	if boxes_share_circuit(boxes[:], dist.box_0, dist.box_1) { continue }

	first_box_0: u16 = get_first_circuit_box(boxes[:], dist.box_0)
	last_box_0: u16 = get_last_circuit_box(boxes[:], dist.box_0)
	first_box_1: u16 = get_first_circuit_box(boxes[:], dist.box_1)
	boxes[last_box_0].next_box = first_box_1
	boxes[first_box_1].prev_box = last_box_0
	last_conn_box_0, last_conn_box_1 = boxes[dist.box_0], boxes[dist.box_1]

	if get_circuit_length_from_start(boxes[:], first_box_0) >= box_count { break }
    }

    fmt.printfln("Last connection:")
    fmt.printfln("Box 0: pos = (%.0f, %.0f, %.0f)", last_conn_box_0.pos.x, last_conn_box_0.pos.y, last_conn_box_0.pos.z)
    fmt.printfln("Box 1: pos = (%.0f, %.0f, %.0f)", last_conn_box_1.pos.x, last_conn_box_1.pos.y, last_conn_box_1.pos.z)
    fmt.printf("\n")

    last_connection_x_product = uint(last_conn_box_0.pos.x + 0.5) * uint(last_conn_box_1.pos.x + 0.5)
    circuit_3_size_product = uint(circuits[0].length) * uint(circuits[1].length) * uint(circuits[2].length)

    return circuit_3_size_product, last_connection_x_product, true
}

get_first_circuit_box :: proc(boxes: []JunctionBox, box_i: BoxId) -> BoxId
{
    return boxes[box_i].prev_box == max(BoxId) ? box_i : get_first_circuit_box(boxes, boxes[box_i].prev_box)
}

get_last_circuit_box :: proc(boxes: []JunctionBox, box_i: BoxId) -> BoxId
{
    return boxes[box_i].next_box == max(BoxId) ? box_i : get_last_circuit_box(boxes, boxes[box_i].next_box)
}

get_circuit_length_from_start :: proc(boxes: []JunctionBox, box_i: BoxId, offset: u16 = 0) -> u16
{
    return boxes[box_i].next_box == max(BoxId) ? offset + 1 : get_circuit_length_from_start(boxes, boxes[box_i].next_box, offset + 1)
}

get_circuit_length :: proc(boxes: []JunctionBox, box_0: BoxId) -> (length: u16)
{
    length = 0
    box_i := box_0
    for boxes[box_i].prev_box != max(BoxId)
    {
	box_i = boxes[box_i].prev_box
	length += 1
    }

    box_i = box_0
    for boxes[box_i].next_box != max(BoxId)
    {
	box_i = boxes[box_i].next_box
	length += 1
    }

    return length
}

boxes_share_circuit :: proc(boxes: []JunctionBox, box_0: BoxId, box_1: BoxId) -> bool
{
    if box_0 == box_1 { return true }

    box_i := box_0
    for boxes[box_i].prev_box != max(BoxId)
    {
	if boxes[box_i].prev_box == box_1 { return true }
	box_i = boxes[box_i].prev_box
    }

    box_i = box_0
    for boxes[box_i].next_box != max(BoxId)
    {
	if boxes[box_i].next_box == box_1 { return true }
	box_i = boxes[box_i].next_box
    }

    return false
}

get_distance_sq :: #force_inline proc(pos_0: Vec3, pos_1: Vec3) -> f32
{
    diff: Vec3 = pos_1 - pos_0
    return linalg.vector_length2(diff)
}

circuit_cmp_rev :: proc(circuit_a: Circuit, circuit_b: Circuit) -> int
{
    return int(circuit_a.length < circuit_b.length) + -int(circuit_a.length > circuit_b.length)
}

dist_cmp :: proc(dist_a: BoxDistance, dist_b: BoxDistance) -> int
{
    return -int(dist_a.value < dist_b.value) + int(dist_a.value > dist_b.value)
}

_print_type_size :: proc($T: typeid)
{
    fmt.printfln("size_of(%v): %d", typeid_of(T), size_of(T))
}
