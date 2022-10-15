package main

import "core:fmt"
import "core:os"
import "core:sync"
import "core:time"
import "core:log"
import "shared:tsv"
import "shared:tsv/frame"
import "shared:tsv/db"
import "shared:bintree"

TEST_FILE_PATH :: "test.tdb"
MODE_PERM :: 0o0777

os_seek :: proc(handle: rawptr, offset: i64, whence: int) -> (i64, tsv.ExternalError) {
    ptr := cast(^os.Handle)handle
    a, b := os.seek(ptr^, offset, whence)
    return a, tsv.ExternalError{
        id=cast(tsv.ErrID)b,
    }
}

os_read :: proc(handle: rawptr, data: []byte) -> (int, tsv.ExternalError) {
    ptr := cast(^os.Handle)handle
    a, b := os.read(ptr^, data)
    err := tsv.ExternalError{
        id=cast(tsv.ErrID)b,
    }
    return a, err
}

os_write :: proc(handle: rawptr, data: []byte) -> (int, tsv.ExternalError) {
	ptr := cast(^os.Handle)handle
	a, b := os.write(ptr^, data)
    err := tsv.ExternalError{
        id=cast(tsv.ErrID)b,
    }
	return a, err
}

remove_test_db :: proc() {
    os.remove(TEST_FILE_PATH)
}

create_test_db_file_handle :: proc() -> (os.Handle, os.Errno) {
    f, err := os.open(TEST_FILE_PATH, os.O_RDWR|os.O_CREATE, MODE_PERM)
    return f, err
}

// write_tsv_file_header :: proc(f: os.Handle) -> (int, os.Errno) {
//     head := tsv.Header{
//         magic = KATTAS_BIRTHDAY,
//     }
//     head.root_ei_pos = size_of(head)
//     if err :=  tsv.write_header_to(f, head); err != os.ERROR_NONE {
//         return 0, err
//     }

//     return size_of(head), 0
// }

// write_tsv_event_block_header :: proc(f: os.Handle) -> os.Errno {
//     time_now := time.now()
//     time_unix_u32 := u32(time.time_to_unix(time_now))
//     evt := tsv.EventBlockHeader{
//         id=1,
//         size=128,
//         start_time=time_unix_u32,
//         // in seconds this is about 3 days
//         elapsed_duration=259200,
//     }
//     log.infof("Size of event block header: %v", size_of(evt))
//     log.infof("alloc'ing events block to %s", TEST_FILE_PATH)
//     if err := tsv.write_empty_event_block(f, evt); err != os.ERROR_NONE {
//         return err
//     }

//     return os.ERROR_NONE
// }

// make_test_db :: proc() {
//     f, err := create_test_db_file_handle()
//     if err != os.ERROR_NONE {
//         log.panicf("error: %d", err)
//     }
//     defer os.close(f)

//     head_size: int
//     head_size, err = write_tsv_file_header(f)
//     if err != os.ERROR_NONE {
//         log.panicf("unable to write header: %v", err)
//     }

//     os.seek(f, i64(head_size), 0)

//     if err = write_tsv_event_block_header(f); err != os.ERROR_NONE {
//         log.panicf("unable to write event block: %v", err)
//     }
// }

// resolve_total_time_duration :: proc(reader: tsv.Reader) {
//     head := tsv.read_header_v2(reader)
//     reader.seek_fn(reader.reader_context, size_of(head), 0)
//     log.infof("head magic: %d", head.magic)
// }

// acquire_tsv_file_total_time_duration :: proc(path: string) -> time.Duration {
//     f, err := os.open(TEST_FILE_PATH, os.O_RDWR, MODE_PERM)
//     if err != os.ERROR_NONE {
//         fmt.printf("error: %d\n", err)
//     }
//     defer os.close(f)

//     head := tsv.read_header(f)

//     os.seek(f, i64(head.root_ei_pos), 0)

//     event_head := tsv.read_event_block_header(f)

//     start := time.unix(i64(event_head.start_time), 0)
//     end := time.unix(i64(event_head.start_time+event_head.elapsed_duration), 0)
//     log.infof("START DATE: %d-%d-%d | END DATE: %d-%d-%d", time.date(start), time.date(end))

//     return time.diff(start, end)
// }

Tsv_Logger_Opts :: log.Options{
	// .Level,
	.Terminal_Color,
	// .Short_File_Path,
	// .Line,
	// .Procedure,
}

main :: proc() {
    f, err := os.open(TEST_FILE_PATH, os.O_RDWR|os.O_CREATE|os.O_TRUNC, MODE_PERM)
    if err != os.ERROR_NONE {
        fmt.printf("error: %d\n", err)
    }
    defer os.close(f)

    reader := tsv.make_reader(os_read, os_seek, cast(rawptr)&f)
    writer := tsv.make_writer(os_write, os_seek, cast(rawptr)&f)

    logger := log.create_console_logger(log.Level.Debug, Tsv_Logger_Opts)
    defer log.destroy_console_logger(logger)
    context.logger = logger
    log.info("running TSV prototype")

    tdb := db.new_db()
    if err := db.write(writer, tdb); err.id != tsv.ERROR_NONE {
        log.fatalf("failed to write tsv db to writer: %s", err.msg)
    }

    output_tdb_header(reader)

    fr := frame.create(3, 3)
    defer frame.destroy(fr)
    frame.fill_random(fr)

    for i := 0; i < 10; i += 1 {
        if err := db.put_frame(writer, &tdb, fr); err.id != tsv.ERROR_NONE {
            log.fatalf("failed to write frame to tsv db: %s", err.msg)
        }
    }
}

output_tdb_header :: proc(reader: tsv.Reader) {
    read_tdb := new(db.DB)
    defer free(read_tdb)
    if err := db.read(reader, read_tdb); err.id != tsv.ERROR_NONE {
        log.fatalf("unable to open tsv db: %s", err.msg)
    }

    log.info(read_tdb.header.magic)
    log.info(read_tdb.root_events_header.entries_count)
}
