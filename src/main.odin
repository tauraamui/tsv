package main

import "core:fmt"
import "core:os"
import "core:sync"
import "core:time"
import "shared:tsv"
import "core:log"

TEST_FILE_PATH :: "test.tdb"
KATTAS_BIRTHDAY :: 0x132BB6C
MODE_PERM :: 0o0777

make_test_db :: proc() {
    log.infof("removing %s", TEST_FILE_PATH)
    os.remove(TEST_FILE_PATH)
    f, err := os.open(TEST_FILE_PATH, os.O_RDWR|os.O_CREATE, MODE_PERM)
    if err != os.ERROR_NONE {
        fmt.printf("error: %d\n", err)
    }
    defer os.close(f)

    head := tsv.FileHeader{
        magic = KATTAS_BIRTHDAY,
    }
    log.infof("Size of file header: %v", size_of(head))
    log.infof("writing header to %s", TEST_FILE_PATH)
    if err :=  tsv.write_header_to(f, head); err != os.ERROR_NONE {
        log.errorf("unable to write header: %v", err)
        os.exit(1)
    }

    os.seek(f, size_of(head), 0)

    time_now := time.now()
    time_unix_u32 := u32(time.time_to_unix(time_now))
    evt := tsv.EventBlockHeader{
        id=1,
        size=128,
        start_time=time_unix_u32,
        // in seconds this is about 3 days
        elapsed_duration=10800,
    }
    log.infof("Size of event block header: %v", size_of(evt))
    log.infof("alloc'ing events block to %s", TEST_FILE_PATH)
    if err := tsv.write_empty_event_block(f, evt); err != os.ERROR_NONE {
        log.errorf("unable to alloc events block: %v\n", err)
        os.exit(1)
    }
}

main :: proc() {
    context.logger = log.create_console_logger(log.Level.Debug)
    log.info("running TSV prototype")
    make_test_db()
}
