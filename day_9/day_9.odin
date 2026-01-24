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
    largest_area, largest_area_in_polygon, parse_success := find_largest_rectangle(input_data_s)
    tsc_elapsed = time.read_cycle_counter() - tsc_elapsed
    fmt.printfln("Took %.5f ms", (f64(tsc_elapsed) / f64(tsc_freq)) * 1000)
    if !parse_success
    {
	fmt.printfln("Error: Failed to parse input file.")
	return
    }

    fmt.printfln("Largest potential rectangle area: %d", largest_area)
    fmt.printfln("Largest potential rectangle area fully contained in polygon: %d", largest_area_in_polygon)
    fmt.printfln("Press any key to exit...")
    tmp_buf: [1]u8
    os.read(os.stdin, tmp_buf[:]) 
}

Vertex :: struct
{
    x, y: i32
}

EdgeOrientation :: enum i16
{
    horizontal = 0,
    vertical = 1
}

Edge :: struct
{
    offset: i32,
    min, max: i32,
    dir: i16,
    orientation: EdgeOrientation
}

find_largest_rectangle :: proc(input: string) -> (largest_area: uint, largest_area_in_polygon: uint, ok: bool)
{
    largest_area = 0
    largest_area_in_polygon = 0

    vertices_cap :: 1000
    vertices: [vertices_cap]Vertex = {}
    vertices_count: int = 0

    read_s: string = input
    for line in strings.split_lines_iterator(&read_s)
    {
	vertex: ^Vertex = &vertices[vertices_count]
	r_line: string = line
	num_s, ok := strings.split_iterator(&r_line, ",")
	num, parse_ok := strconv.parse_int(num_s)
	vertex.x = i32(num)
	num_s, ok = strings.split_iterator(&r_line, ",")
	num, parse_ok = strconv.parse_int(num_s)
	vertex.y = i32(num)

	vertices_count += 1
    }

    v_edges: [vertices_cap]Edge = {}
    v_edges_count: int = 0
    h_edges: [vertices_cap]Edge = {}
    h_edges_count: int = 0
    first_edge, last_edge: ^Edge = nil, nil
    for vertex, vertex_i in vertices[:vertices_count]
    {
	last_vertex: Vertex = vertices[(vertex_i - 1) %% vertices_count]
	cur_edge: ^Edge = nil
	switch
	{
	case vertex.x == last_vertex.x:
	    cur_edge = &v_edges[v_edges_count]
	    cur_edge^ = { min = last_vertex.y, max = vertex.y }
	    cur_edge.dir = last_vertex.y <= vertex.y ? 1 : -1
	    cur_edge.offset = vertex.x + i32(cur_edge.dir)
	    cur_edge.orientation = .vertical
	    v_edges_count += 1
	case vertex.y == last_vertex.y:
	    cur_edge = &h_edges[h_edges_count]
	    cur_edge^ = { min = last_vertex.x, max = vertex.x }
	    cur_edge.dir = last_vertex.x <= vertex.x ? 1 : -1
	    cur_edge.offset = vertex.y - i32(cur_edge.dir)
	    cur_edge.orientation = .horizontal
	    h_edges_count += 1
	case:
	    fmt.printfln("Error: Failed to parse axis-aligned edge to vertex %d", vertex_i + 1)
	    return 0, 0, false
	}

	if last_edge == nil 
	{
	    first_edge = cur_edge
	    last_edge = cur_edge
	    continue
	}

	adjust_edges_for_concave_corners(last_edge, cur_edge)
	if last_edge != first_edge && last_edge.dir == -1 { last_edge.min, last_edge.max = last_edge.max, last_edge.min }

	last_edge = cur_edge
    }

    adjust_edges_for_concave_corners(last_edge, first_edge)
    if last_edge.dir == -1 { last_edge.min, last_edge.max = last_edge.max, last_edge.min }
    if first_edge.dir == -1 { first_edge.min, first_edge.max = first_edge.max, first_edge.min }

    for v0_i in 0 ..< vertices_count
    {
	for v1_i in v0_i + 1 ..< vertices_count
	{
	    v0: Vertex = vertices[v0_i]
	    v1: Vertex = vertices[v1_i]

	    width: i32 = abs(v1.x - v0.x) + 1
	    height: i32 = abs(v1.y - v0.y) + 1
	    area: uint = uint(width) * uint(height)

	    largest_area = max(area, largest_area)

	    (rect_contained_in_polygon(v0, v1, v_edges[0:v_edges_count], h_edges[0:h_edges_count])) or_continue

	    largest_area_in_polygon = max(area, largest_area_in_polygon)
	}
    }

    return largest_area, largest_area_in_polygon, true
}

adjust_edges_for_concave_corners :: proc(edge0: ^Edge, edge1: ^Edge)
{
    if edge0.orientation == edge1.orientation
    {
	edge1.min += i32(edge1.dir)
    }
    else
    {
	concave: bool = (edge0.orientation == .horizontal && edge0.dir != edge1.dir) || (edge0.orientation == .vertical && edge0.dir == edge1.dir)
	edge0.max -= concave ? i32(edge0.dir) : 0
	edge1.min += concave ? i32(edge1.dir) : 0
    }
}

// NOTE: Expects edge's min and max to be ordered independently of original draw direction
rect_contained_in_polygon :: proc(v0: Vertex, v1: Vertex, vertical_edges: []Edge, horizontal_edges: []Edge) -> (in_poly: bool)
{
    v2: Vertex = { v0.x, v1.y }
    v3: Vertex = { v1.x, v0.y }
    vertices: [4]Vertex = { v3, v2, v1, v0 }

    first_intersection_count: uint = 0 
    for v in vertices
    {
	intersection_count: uint = 0
	for edge in vertical_edges
	{
	    (edge.offset > v.x) or_continue
	    if v.y >= edge.min && v.y <= edge.max { intersection_count += 1 }
	}

	if first_intersection_count == 0 { first_intersection_count = intersection_count }
	if intersection_count != first_intersection_count || (intersection_count % 2) == 0 { return false }
    }

    first_intersection_count = 0 
    for v in vertices
    {
	intersection_count: uint = 0
	for edge in horizontal_edges
	{
	    (edge.offset > v.y) or_continue
	    if v.x >= edge.min && v.x <= edge.max { intersection_count += 1 }
	}

	if first_intersection_count == 0 { first_intersection_count = intersection_count }
	if intersection_count != first_intersection_count || (intersection_count % 2) == 0 { return false }
    }

    return true
}

// NOTE: Expects edge's min and max to be ordered independently of original draw direction
vertex_contained_in_polygon :: proc(v: Vertex, vertical_edges: []Edge, horizontal_edges: []Edge) -> (h_intersect_count: uint, v_intersect_count: uint, in_poly: bool)
{
    h_intersect_count = 0
    v_intersect_count = 0

    for edge in vertical_edges
    {
	(edge.offset > v.x) or_continue
	if v.y >= edge.min && v.y <= edge.max { h_intersect_count += 1 }
    }

    if (h_intersect_count % 2) == 0
    {
	return h_intersect_count, v_intersect_count, false
    }

    for edge in horizontal_edges
    {
	(edge.offset > v.y) or_continue
	if v.x >= edge.min && v.x <= edge.max { v_intersect_count += 1 }
    }

    return h_intersect_count, v_intersect_count, (v_intersect_count % 2) != 0
}

_print_type_size :: proc($T: typeid)
{
    fmt.printfln("size_of(%v): %d", typeid_of(T), size_of(T))
}
