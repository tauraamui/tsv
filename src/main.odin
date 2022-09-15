package main

import "core:fmt"
import "core:os"
import "core:sync"
import "core:time"
import "shared:tsv"
import "core:log"

TEST_FILE_PATH :: "test.tdb"
MODE_PERM :: 0o0777

os_seek :: proc(handle: rawptr, offset: i64, whence: int) -> (i64, int) {
    ptr := cast(^os.Handle)handle
    file_size, err := os.file_size(ptr^)
    log.debug("file size", file_size)
    if file_size == 0 || err != os.ERROR_NONE {
        return 0, cast(int)err
    }
    a, b := os.seek(ptr^, offset, whence)
    return a, cast(int)b
}

os_read :: proc(handle: rawptr, data: []byte) -> (int, int) {
    ptr := cast(^os.Handle)handle
    a, b := os.read(ptr^, data)
    return a, cast(int)b
}

os_write :: proc(handle: rawptr, data: []byte) -> (int, int) {
	ptr := cast(^os.Handle)handle
	a, b := os.write(ptr^, data)
	return a, cast(int)b
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

    logger := log.create_console_logger(log.Level.Info, Tsv_Logger_Opts)
    context.logger = logger
    log.info("running TSV prototype")

    new_tsvid := tsv.new()
    log.debug("writing new db")
    if ok := tsv.store(writer, new_tsvid); !ok {
        log.panic("ERROR: unable to create new tsv DB")
    }

    tsvid, ok := tsv.load(reader)
    if !ok {
        log.panic("ERROR: unable to load tsv DB")
    }

    log.infof("magic: %d", tsvid.header.magic)

    tsvid.root_events_block_header.frame_size = 2000
    tsvid.root_events_block_header.fps = 25
    if ok := tsv.store(writer, tsvid); !ok {
        log.panic("ERROR: unable to update tsv DB")
    }
}
