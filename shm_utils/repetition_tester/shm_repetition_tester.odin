package shm_repetition_tester

import "core:fmt"
import "core:time"
import "core:os"
import utils ".."

@private
TestResultType :: enum
{
    TSC,
    BytesProcessed,
    PageFaultCount
}

@private
TestResults :: struct
{
    run_count: u64,
    max: [len(TestResultType)]u64,
    min: [len(TestResultType)]u64,
    total: [len(TestResultType)]u64,
}

RepetitionTester :: struct
{
    test_runtime_duration: f64,
    tsc_frequency: u64,
    tsc_last_test_start: u64,
    run_results: [len(TestResultType)]u64,
    test_results: TestResults
}

@private
ResultsTableLabel :: struct
{
    buf: [64]u8
}

ResultsTable :: struct
{
    max_row_count: u32,
    column_count: u32,
    row_count: u32,
    row_label_label: ResultsTableLabel,
    column_labels: []ResultsTableLabel,
    row_labels: []ResultsTableLabel,
    results: []TestResults,
    buf: [^]byte
}

PrintValueType :: enum
{
    GiBPerSecond
}

tester_init :: proc(out_tester: ^RepetitionTester, test_runtime_duration: f64, tsc_frequency: u64 = 0) -> (ok: bool)
{
    out_tester.tsc_frequency = tsc_frequency
    if out_tester.tsc_frequency == 0 { out_tester.tsc_frequency, _ = time.tsc_frequency() }
    out_tester.test_runtime_duration = test_runtime_duration

    return true
}

tester_begin_test :: proc(tester: ^RepetitionTester, test_name: string) -> (ok: bool)
{
    tester.test_results.run_count = 0
    for type_i in TestResultType
    {
	tester.run_results[type_i] = 0
	tester.test_results.min[type_i] = max(u64)
	tester.test_results.max[type_i] = 0
	tester.test_results.total[type_i] = 0
    }

    fmt.printfln("Running repetition test '%s':", test_name)
    tester.tsc_last_test_start = 0
    return true
}

tester_next_run :: proc(tester: ^RepetitionTester, log_temp_stats: bool) -> (ok: bool)
{
    if tester.tsc_last_test_start == 0
    {
	tester.tsc_last_test_start = time.read_cycle_counter()
	return true
    }

    for type_i in TestResultType
    {
	run_result: u64 = tester.run_results[type_i]
	tester.run_results[type_i] = 0
	test_result: ^TestResults = &tester.test_results
	test_result.total[type_i] += run_result
	test_result.min[type_i] = min(run_result, test_result.min[type_i])
	test_result.max[type_i] = max(run_result, test_result.min[type_i])
    }

    tester.test_results.run_count += 1
    total_seconds_elapsed: f64 = _tsc_to_s(tester.tsc_frequency, (time.read_cycle_counter() - tester.tsc_last_test_start))
    if log_temp_stats
    {
	fmt.printf("Run count: %d, Total time elapsed: %.5fs, Current minimal time: %.5fms\r",
	    tester.test_results.run_count, total_seconds_elapsed, _tsc_to_s(tester.tsc_frequency, tester.test_results.min[TestResultType.TSC]) * 1000)
    }

    return total_seconds_elapsed < tester.test_runtime_duration
}

tester_print_last_test_results :: proc(tester: ^RepetitionTester)
{
    _print_test_results(tester)
}

test_begin_timer :: proc(tester: ^RepetitionTester)
{
    tester.run_results[TestResultType.TSC] -= time.read_cycle_counter()
    tester.run_results[TestResultType.PageFaultCount] -= 0
}

test_end_timer :: proc(tester: ^RepetitionTester)
{
    tester.run_results[TestResultType.TSC] += time.read_cycle_counter()
    tester.run_results[TestResultType.PageFaultCount] += 0
}

test_add_bytes_processed :: proc(tester: ^RepetitionTester, bytes_count: u64)
{
    tester.run_results[TestResultType.BytesProcessed] += bytes_count
}

test_log_error :: proc(tester: ^RepetitionTester, msg: string)
{
    fmt.printfln("Test Error: %s", msg)
}

results_table_init :: proc(column_count: u32, max_row_count: u32, row_label_label: string, out_table: ^ResultsTable, allocator := context.allocator) -> (ok: bool)
{
    out_table.column_count = column_count
    out_table.max_row_count = max_row_count
    out_table.row_count = 0

    column_labels_size: u64 = u64(column_count) * size_of(out_table.column_labels[0])
    row_labels_size: u64 = u64(max_row_count) * size_of(out_table.row_labels[0])
    results_size: u64 = u64(column_count) * u64(max_row_count) * size_of(out_table.results[0])
    alloc_size: u64 = column_labels_size + row_labels_size + results_size
    buf, tracker, _ := utils.sub_alloc_start(alloc_size, allocator)
    out_table.buf = buf
    utils.sub_alloc_next(out_table.buf, &tracker, u64(column_count), &out_table.column_labels)
    utils.sub_alloc_next(out_table.buf, &tracker, u64(max_row_count), &out_table.row_labels)
    utils.sub_alloc_next(out_table.buf, &tracker, u64(column_count) * u64(max_row_count), &out_table.results)

    utils.string_copy_to_u8(row_label_label, out_table.row_label_label.buf[:])
    return true
}

results_table_destroy :: proc(table: ^ResultsTable, allocator := context.allocator)
{
    mem_free(table.buf, allocator)
    table^ = {}
}

results_table_set_column_label :: proc(table: ^ResultsTable, col_index: u32, label: string)
{
    if col_index >= table.column_count { return }
    utils.string_copy_to_u8(label, table.column_labels[col_index].buf[:])
}

results_table_add_row :: proc(table: ^ResultsTable, row_label: string) -> u32
{
    if table.row_count >= table.max_row_count { return table.max_row_count - 1 }
    row_index := table.row_count
    utils.string_copy_to_u8(row_label, table.row_labels[row_index].buf[:])
    table.row_count += 1
    return row_index
}

tester_results_table_add_last_result :: proc(tester: ^RepetitionTester, table: ^ResultsTable, col_index: u32, row_index: u32)
{
    if col_index >= table.column_count || row_index >= table.row_count { return }
    table.results[(row_index * table.column_count) + col_index] = tester.test_results
}

tester_results_table_print_as_csv :: proc(tester: ^RepetitionTester, table: ^ResultsTable, print_value_type: PrintValueType, out_csv_filepath: string = "")
{
    file: os.Handle = {}
    if len(out_csv_filepath) == 0 { file = os.stdout }
    else { file, _ = os.open(out_csv_filepath, os.O_CREATE | os.O_APPEND) }

    csv_del: u8 = ';'
    fmt.fprintf(file, "%s", table.row_label_label.buf)
    for col in table.column_labels[0:table.column_count]
    {
	fmt.fprintf(file, "%c%s", csv_del, col.buf)
    }
    fmt.fprintf(file, "\n")

    for row, row_i in table.row_labels[0:table.row_count]
    {
	fmt.fprintf(file, "%s", row.buf)
	for col_i in 0 ..< table.column_count
	{
	    fmt.fprintf(file, "%c", csv_del)
	    results: TestResults = table.results[(u32(row_i) * table.column_count) + col_i]
	    avg_tsc: u64 = results.total[TestResultType.TSC] / results.run_count
	    avg_bytes: u64 = results.total[TestResultType.BytesProcessed] / results.run_count
	    avg_p_faults: u64 = results.total[TestResultType.PageFaultCount] / results.run_count
	    seconds: f64 = _tsc_to_s(tester.tsc_frequency, avg_tsc)

	    switch print_value_type
	    {
	    case .GiBPerSecond:
		fmt.fprintf(file, "%.5f", seconds == 0 ? 0.0 : f64(avg_bytes) / utils.GiB / seconds)
	    }
	}
	fmt.fprintf(file, "\n")
    }

    if len(out_csv_filepath) == 0 { fmt.fprintf(file, "\n") }
    else { os.close(file) }
}

@private
_tsc_to_s :: proc(freq: u64, tsc: u64) -> f64
{
    return f64(tsc) / f64(freq)
}

@private
_print_result_line :: proc(label: string, values: []u64, invalid_value: u64, tsc_frequency: u64)
{
    tsc: u64 = values[TestResultType.TSC]
    bytes: u64 = values[TestResultType.BytesProcessed]
    p_faults: u64 = values[TestResultType.PageFaultCount]
    seconds: f64 = _tsc_to_s(tsc_frequency, tsc)

    fmt.printfln("%s: Time: %.5fms (%d), Data: %dB (%.5fgib/s), Page Faults: %d (%.5fkib/fault)",
	label, seconds * 1000, tsc, bytes, tsc == invalid_value ? 0.0 : (f64(bytes) / utils.GiB / seconds), p_faults, p_faults == 0 ? 0.0 : (f64(bytes) / f64(p_faults) * utils.KiB))
}

@private
_print_test_results :: proc(tester: ^RepetitionTester)
{
    fmt.printfln("Run count: %d, Total time elapsed: %.5fs", tester.test_results.run_count, _tsc_to_s(tester.tsc_frequency, (time.read_cycle_counter() - tester.tsc_last_test_start)))

    averages: [len(TestResultType)]u64 = {}
    for value_i in 0 ..< len(averages) { averages[value_i] = tester.test_results.total[value_i] / tester.test_results.run_count }

    _print_result_line("Min:", tester.test_results.min[:], max(u64), tester.tsc_frequency)
    _print_result_line("Max:", tester.test_results.max[:], 0, tester.tsc_frequency)
    _print_result_line("Avg:", averages[:], 0, tester.tsc_frequency)
    fmt.printf("\n")
}
