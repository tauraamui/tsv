package db

import "core:fmt"
import "shared:tsv"
import "shared:tsv/frame"

@(private)
MAGIC :: 0x132BB6C

DB :: struct {
    header:                   Header,
    root_events_header:       SimpleEventBlockHeader,
    // root_events_block_header: EventsBlockHeader,
}

new_db :: proc() -> DB {
    return DB{
        header=Header{
            magic=MAGIC,
            root_ei_pos=size_of(Header{}),
        },
        root_events_header=SimpleEventBlockHeader{
            id=0,
            entries_count=0,
        },
        // root_events_block_header=EventsBlockHeader{
        //     id=1,
        //     size=1024,
        //     duration=0,
        //     fps=0,
        //     frame_size=0,
        // },
    }
}

write :: proc(writer: tsv.Writer, tdb: DB) -> tsv.Error {
    if ok, err := tsv.seek_writer(writer, 0); !ok {
        return tsv.Error{
            id=tsv.ERROR_SEEK,
            msg=fmt.tprintf("failed to seek writer: %s", err.msg),
        }
    }

    if ok, err := write_header(writer, tdb.header); !ok {
        return tsv.Error{
            id=tsv.ERROR_WRITE,
            msg=fmt.tprintf("failed to write header: %s", err.msg),
        }
    }

    if ok, err := tsv.seek_writer(writer, i64(tdb.header.root_ei_pos)); !ok {
        return tsv.Error{
            id=tsv.ERROR_SEEK,
            msg=fmt.tprintf("failed to seek writer to pos %d: %s", tdb.header.root_ei_pos, err.msg),
        }
    }

    if err := write_events_header(writer, tdb.root_events_header); err.id != tsv.ERROR_NONE {
        return tsv.Error{
            id=tsv.ERROR_WRITE,
            msg=fmt.tprintf("failed to write root events block header: %s", err.msg),
        }
    }

    return tsv.Error{
        id=tsv.ERROR_NONE,
    }
}

put_frame :: proc(writer: tsv.Writer, tdb: ^DB, fr: frame.Frame) -> tsv.Error {
    c_id := tdb.root_events_header.entries_count
    new_id: uint32 = c_id + 1

    event_block_start := (tdb.header.root_ei_pos + size_of(tdb.root_events_header))
    existing_size := (c_id * size_of(EventBlockEntry))

    if existing_size + size_of(EventBlockEntry) > MAX_EVENT_SIZE {
        return tsv.Error{
            id=tsv.ERROR_WRITE,
            msg=fmt.tprintf("event block max size will be supassed by new entry write"),
        }
    }

    write_loc := event_block_start + existing_size
    if ok, err := tsv.seek_writer(writer, i64(write_loc)); !ok {
        return tsv.Error{
            id=tsv.ERROR_SEEK,
            msg=fmt.tprintf("failed to seek writer to pos %d: %s", tdb.header.root_ei_pos, err.msg),
        }
    }

    if err := write_events_entry(writer, EventBlockEntry{new_id}); err.id != tsv.ERROR_NONE {
        return tsv.Error{
            id=tsv.ERROR_WRITE,
            msg=fmt.tprintf("failed to write entry to events block: %s", err.msg),
        }
    }

    updated_block_header := SimpleEventBlockHeader{
        id=tdb.root_events_header.id,
        entries_count=new_id,
    }

    if ok, err := tsv.seek_writer(writer, i64(tdb.header.root_ei_pos)); !ok {
        return tsv.Error{
            id=tsv.ERROR_SEEK,
            msg=fmt.tprintf("failed to seek writer to pos %d: %s", tdb.header.root_ei_pos, err.msg),
        }
    }

    if err := write_events_header(writer, updated_block_header); err.id != tsv.ERROR_NONE {
        return tsv.Error{
            id=tsv.ERROR_WRITE,
            msg=fmt.tprintf("failed to write root events block header: %s", err.msg),
        }
    }

    tdb.root_events_header = updated_block_header

    // jump to end of event block, apply current count as offset and write frame data

    return tsv.Error{
        id=tsv.ERROR_NONE,
    }
}

read :: proc(reader: tsv.Reader, dst: ^DB) -> tsv.Error {
    if ok, err := tsv.seek_reader(reader, 0); !ok {
        return tsv.Error{
            id=tsv.ERROR_SEEK,
            msg=fmt.tprintf("failed to seek writer: %s", err.msg),
        }
    }

    head, err := read_header(reader)
    if err.id != tsv.ERROR_NONE {
        return tsv.Error{
            id=err.id,
            msg=fmt.tprintf("failed to read header: %s", err.msg),
        }
    }

    dst.header = head

    if ok, err := tsv.seek_reader(reader, i64(dst.header.root_ei_pos)); !ok {
        return tsv.Error{
            id=tsv.ERROR_SEEK,
            msg=fmt.tprintf("failed to seek: %s", err.msg),
        }
    }

    events_block_header: SimpleEventBlockHeader
    events_block_header, err = read_events_header(reader)
    if err.id != tsv.ERROR_NONE {
        return tsv.Error{
            id=err.id,
            msg=fmt.tprintf("failed to read root events block header: %s", err.msg),
        }
    }

    dst.root_events_header = events_block_header

    return tsv.Error{
        id=tsv.ERROR_NONE,
    }
}
