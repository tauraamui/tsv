package main

import "core:fmt"
import "core:os"
import "core:sync"
import "core:time"
import "core:log"
import "shared:tsv"
import "shared:tsv/frame"
import "shared:tsv/db"
import "shared:tsv/error"
import "shared:bintree"

TEST_FILE_PATH :: "test.tdb"
MODE_PERM :: 0o0777

os_seek :: proc(handle: rawptr, offset: i64, whence: int) -> (i64, tsv.ExternalError) {
    ptr := cast(^os.Handle)handle
    a, b := os.seek(ptr^, offset, whence)
    return a, tsv.ExternalError{
        id=cast(error.ID)b,
    }
}

os_read :: proc(handle: rawptr, data: []byte) -> (int, tsv.ExternalError) {
    ptr := cast(^os.Handle)handle
    a, b := os.read(ptr^, data)
    err := tsv.ExternalError{
        id=cast(error.ID)b,
    }
    return a, err
}

os_write :: proc(handle: rawptr, data: []byte) -> (int, tsv.ExternalError) {
	ptr := cast(^os.Handle)handle
	a, b := os.write(ptr^, data)
    err := tsv.ExternalError{
        id=cast(error.ID)b,
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

Tsv_Logger_Opts :: log.Options{
	// .Level,
	.Terminal_Color,
	// .Short_File_Path,
	// .Line,
	// .Procedure,
}

main :: proc() {
    f, os_err := os.open(TEST_FILE_PATH, os.O_RDWR|os.O_CREATE|os.O_TRUNC, MODE_PERM)
    if os_err != os.ERROR_NONE {
        fmt.printf("error: %d\n", os_err)
    }
    defer os.close(f)

    reader := tsv.make_reader(os_read, os_seek, cast(rawptr)&f)
    writer := tsv.make_writer(os_write, os_seek, cast(rawptr)&f)

    logger := log.create_console_logger(log.Level.Debug, Tsv_Logger_Opts)
    defer log.destroy_console_logger(logger)
    context.logger = logger
    log.info("running TSV prototype")

    tdb, err := db.new_db(writer, reader)
    if err.id != error.NONE {
        log.fatalf("failed to open conn to tsv db: %s", err.msg)
    }
    // if err := db.write(writer, tdb); err.id != error.NONE {
    //     log.fatalf("failed to write tsv db to writer: %s", err.msg)
    // }

    // output_tdb_header(reader)

    fr := frame.create(3, 3)
    defer frame.destroy(fr)
    frame.fill_random(fr)

    for i := 0; i < 10; i += 1 {
        if err := db.save_frame(tdb, fr); err.id != error.NONE {
            log.fatalf("failed to write frame to tsv db: %s", err.msg)
        }
    }
}

output_tdb_header :: proc(reader: tsv.Reader) {
    read_tdb := new(db.DB)
    defer free(read_tdb)
    if err := db.read(reader, read_tdb); err.id != error.NONE {
        log.fatalf("unable to open tsv db: %s", err.msg)
    }

    log.info(read_tdb.header.magic)
    log.info(read_tdb.root_events_header.entries_count)
}
