package main

import "core:fmt"
import "core:os"
import "core:sync"
import "shared:tsv"
import "core:log"

TEST_FILE_PATH :: "test.tdb"
KATTAS_BIRTHDAY :: 0x132BB6C
MODE_PERM :: 0o0777

main :: proc() {
    context.logger = log.create_console_logger(log.Level.Debug)
    log.info("running TSV prototype")
    log.infof("removing %s", TEST_FILE_PATH)
    os.remove(TEST_FILE_PATH)
    f, err := os.open(TEST_FILE_PATH, os.O_RDWR|os.O_CREATE, MODE_PERM)
    if err != os.ERROR_NONE {
        fmt.printf("error: %d\n", err)
    }
    defer os.close(f)

    head := tsv.Header{
        magic = KATTAS_BIRTHDAY,
        start_timestamp = 1662762919,
        elapsed_duration = 0,
    }
    log.infof("writing header to %s", TEST_FILE_PATH)
    if err :=  tsv.write_header_to(f, head); err != os.ERROR_NONE {
        log.errorf("unable to write header: %v", err)
        os.exit(1)
    }

    evt := tsv.EventBlock{
        id=1,
        size=256,
    }
    log.infof("alloc'ing events block to %s", TEST_FILE_PATH)
    if err := tsv.allocate_event_block(f, evt); err != os.ERROR_NONE {
        log.errorf("unable to alloc events block: %v\n", err)
        os.exit(1)
    }
}
