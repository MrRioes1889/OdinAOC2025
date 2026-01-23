package shm_utils

import "core:mem"
import "core:fmt"

KiB :: 1024
MiB :: KiB * 1024
GiB :: MiB * 1024

SubAllocTracker :: struct
{
    offset: u64,
    size: u64,
}

sub_alloc_start :: proc(size: u64, allocator := context.allocator) -> (buf: [^]byte, tracker: SubAllocTracker, err: mem.Allocator_Error)
{
    err = .None
    buf, err = make([^]byte, size, allocator)
    tracker.size = err == .None ? size : 0
    tracker.offset = 0

    return buf, tracker, err
}

sub_alloc_next_arr:: proc(buf: [^]byte, tracker: ^SubAllocTracker, count: u64, arr: ^[]$T) -> bool
{
    size_left: u64 = tracker.size - tracker.offset
    sub_alloc_size: u64 = count * size_of(T)
    (sub_alloc_size <= size_left) or_return 
    arr^ = (cast([^]T)&buf[tracker.offset])[0:count]
    tracker.offset += sub_alloc_size
    return true
}

sub_alloc_next_single:: proc(buf: [^]byte, tracker: ^SubAllocTracker, obj: ^$T) -> bool
{
    size_left: u64 = tracker.size - tracker.offset
    sub_alloc_size: u64 = size_of(T)
    (sub_alloc_size <= size_left) or_return 
    arr^ = (cast([^]T)&buf[tracker.offset])[0:count]
    tracker.offset += sub_alloc_size
    return true
}

sub_alloc_next :: proc{sub_alloc_next_arr, sub_alloc_next_single}

print_type_size :: proc($T: typeid)
{
    fmt.printfln("%v size: %d", typeid_of(T), size_of(T))
}

string_copy_to_u8 :: proc(str: string, to: []u8)
{
    length := min(len(str), len(to) - 1)
    for i in 0 ..< length
    {
	to[i] = str[i]
    }
    to[length] = 0
}

