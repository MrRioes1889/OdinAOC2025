package shm_profiler

import "core:fmt"
import "core:time"

PROFILER_ENABLED :: true
TIMERS_ENABLED :: true
TIMERS_CAP :: 1023

TimerId :: u32
@private
TimeBlock :: struct
{
    timer_id: TimerId,
    parent_id: TimerId,
    tsc_elapsed_full_carry_offset: u64,
    tsc_start: u64
}

@private
Timer :: struct
{
    tsc_elapsed_self: u64,
    tsc_elapsed_full: u64,
    byte_count_processed: u64,
    call_count: u32,
    key: string
}

@private
Profiler :: struct
{
    tsc_frequency: u64,
    tsc_start: u64,
    timers_count: u32,
    timers: [TIMERS_CAP + 1]Timer
}

@private
_profiler: Profiler = {}
@private
_cur_timer_id: TimerId = 0

@private
_get_next_timer_id :: proc() -> TimerId
{
    _profiler.timers_count = min(_profiler.timers_count + 1, TIMERS_CAP)
    return _profiler.timers_count
}

@private
_timer_start :: proc(key: string, byte_count_processed: u64) -> TimeBlock
{
    timer_id: TimerId = _get_next_timer_id()
    timer: ^Timer = &_profiler.timers[timer_id]
    time_block: TimeBlock = {}

    time_block.parent_id = _cur_timer_id
    time_block.timer_id = timer_id
    time_block.tsc_elapsed_full_carry_offset = timer.tsc_elapsed_full
    timer.key = key
    timer.byte_count_processed += byte_count_processed

    _cur_timer_id = timer_id
    time_block.tsc_start = time.read_cycle_counter()
    return time_block
}

@private @(disabled=!PROFILER_ENABLED || !TIMERS_ENABLED)
_timer_end :: proc(time_block: TimeBlock)
{
    tsc_elapsed: u64 = time.read_cycle_counter() - time_block.tsc_start
    _cur_timer_id = time_block.parent_id

    timer: ^Timer = &_profiler.timers[time_block.timer_id]
    parent: ^Timer = &_profiler.timers[time_block.parent_id]

    parent.tsc_elapsed_self -= tsc_elapsed
    timer.tsc_elapsed_self += tsc_elapsed
    timer.tsc_elapsed_full = time_block.tsc_elapsed_full_carry_offset + tsc_elapsed
    timer.call_count += 1
}

@(disabled=!PROFILER_ENABLED)
profiler_init :: proc(tsc_frequency: u64 = 0)
{
    _profiler.tsc_frequency = tsc_frequency
    if _profiler.tsc_frequency == 0 { _profiler.tsc_frequency, _ = time.tsc_frequency(500 * time.Millisecond) }
    _profiler.timers = {}
    _profiler.timers_count = 0
    _profiler.tsc_start	= time.read_cycle_counter()
}

@(disabled=!PROFILER_ENABLED)
profiler_dump :: proc(reset_profiler: bool = true)
{
    tsc_elapsed: u64 = time.read_cycle_counter() - _profiler.tsc_start

    fmt.printfln("\nProfiler dump:")
    fmt.printfln("RDTSC frequency: %d cycles/second", _profiler.tsc_frequency)
    fmt.printfln("Estimated total time/count: %.5f ms / %d cycles", (f64(tsc_elapsed) / f64(_profiler.tsc_frequency)) * 1000, tsc_elapsed)
    fmt.printfln("Timers:")
    
    for timer in _profiler.timers[1:_profiler.timers_count + 1]
    {
	self_percent: f64 = f64(timer.tsc_elapsed_self) / f64(tsc_elapsed) * 100
	self_seconds: f64 = f64(timer.tsc_elapsed_self) / f64(_profiler.tsc_frequency)
	full_percent: f64 = f64(timer.tsc_elapsed_full) / f64(tsc_elapsed) * 100
	full_seconds: f64 = f64(timer.tsc_elapsed_full) / f64(_profiler.tsc_frequency)

	fmt.printfln("  %s[%d]:\n    self: %.5f ms, %d cycles, %.2f%%\n    full: %.5f ms, %d cycles, %.2f%%",
	    timer.key, timer.call_count, self_seconds * 1000, timer.tsc_elapsed_self, self_percent, full_seconds * 1000, timer.tsc_elapsed_full, full_percent)

	if timer.byte_count_processed > 0
	{
	    mebibyte :: 1024 * 1024
	    processed_mib: f64 = f64(timer.byte_count_processed) / mebibyte
	    gib_per_second: f64 = (processed_mib / 1024) / full_seconds
	    fmt.printfln("    data throughput: %.5f MiB at %.5f GiB/second", processed_mib, gib_per_second)
	}
    }
    fmt.print("\n")

    if reset_profiler { profiler_init(_profiler.tsc_frequency) }
}

when TIMERS_ENABLED && PROFILER_ENABLED
{
    @(deferred_out=_timer_end)
    timer_start_scoped :: proc(key: string, byte_count_processed: u64 = 0) -> TimeBlock
    {
	return _timer_start(key, byte_count_processed)
    }

    @(deferred_out=_timer_end)
    timer_start_scoped_func :: proc(byte_count_processed: u64 = 0, loc := #caller_location) -> TimeBlock
    {
	return _timer_start(loc.procedure, byte_count_processed)
    }
}
else
{
    timer_start_scoped :: proc(key: string, byte_count_processed: u64 = 0) {}
    timer_start_scoped_func :: proc(byte_count_processed: u64 = 0, loc := #caller_location) {}
}

