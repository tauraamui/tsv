package db

import "core:fmt"
import "shared:tsv"
import "shared:tsv/frame"
import "shared:tsv/event"
import "shared:tsv/error"

@(private)
MAGIC :: 0x132BB6C

@(private)
no_err :: error.Error{id=error.NONE}

Connection :: ^DB

DB :: struct {
    writer: tsv.Writer,
    reader: tsv.Reader,
    header: Header,
}

new_db :: proc(writer: tsv.Writer, reader: tsv.Reader) -> (Connection, error.Error) {
    db := DB{
        writer=writer,
        reader=reader,
    }

    h, err := resolve_header(&db)
    if err.id != error.NONE {
        return nil, err
    }

    db.header = h

    return &db, no_err
}

@private
resolve_header :: proc(tdb: Connection) -> (Header, error.Error) {
    existing_header, err := read_header(tdb.reader)

    if err.id != error.NONE && err.id != error.READING_EMPTY {
        return Header{}, err
    }

    if err.id == error.READING_EMPTY {
        h := Header{magic=MAGIC}
        h.root_ei_pos = size_of(h)
        if ok, err := write_header(tdb.writer, h, ROOT_HEADER_POS); !ok {
            return Header{}, err
        }
        return h, no_err
    }

    if existing_header.magic == MAGIC { return existing_header, no_err }

    return Header{}, error.Error{
        id=error.UNKNOWN_HEADER,
        msg=fmt.tprintf("unknown magic value: %v", existing_header.magic),
    }
}

@private
ROOT_HEADER_POS :: 0

write :: proc(writer: tsv.Writer, tdb: DB) -> error.Error {
    if ok, err := write_header(writer, tdb.header, ROOT_HEADER_POS); !ok {
        return error.Error{
            id=error.WRITE,
            msg=fmt.tprintf("failed to write header: %s", err.msg),
        }
    }

    // if err := event.write_header(writer, tdb.root_events_header, i64(tdb.header.root_ei_pos)); err.id != error.NONE {
    //     return error.Error{
    //         id=error.WRITE,
    //         msg=fmt.tprintf("failed to write root events block header: %s", err.msg),
    //     }
    // }

    return no_err
}

// @private
// event_block_start :: proc(tdb: ^DB) -> uint32 {
//     return tdb.header.root_ei_pos + size_of(tdb.root_events_header)
// }

// @private
// calc_existing_size :: proc(tdb: ^DB) -> uint32 {
//     return tdb.root_events_header.entries_count * size_of(event.EventBlockEntry)
// }

// @private
// within_event_block_bounds :: proc(tdb: ^DB) -> bool {
//     return !(calc_existing_size(tdb) + size_of(event.EventBlockEntry) > event.MAX_EVENT_SIZE)
// }

/* This proc needs to do a bunch of tasks, one by one probably
    1. Store event data entry in current event block
        - This will require to track some kind of cursor for a specific event block
    2. Store frame content into current video block
        - The location for the inserts to start from for an event block will always
          be relative to the known max size of the current event block, but as the event
          block is being populated, the actual space it takes up will not extend to its max size
        - Therefore for the first video data insertion the seek will have to occur from the
          start of the current event block + event block's max size
*/
save_frame :: proc(tdb: ^DB, fr: frame.Frame) -> error.Error {
    // PENDING RE-WRITE OF INSERTIONS
    /*
    if !within_event_block_bounds(tdb) {
        return error.Error{
            id=error.WRITE,
            msg=fmt.tprintf("event block max size will be supassed by new entry write"),
        }
    }

    c_id := tdb.root_events_header.entries_count
    new_id: uint32 = c_id + 1

    write_loc := event_block_start(tdb) + calc_existing_size(tdb)
    if ok, err := tsv.seek_writer(writer, i64(write_loc)); !ok {
        return error.Error{
            id=error.SEEK,
            msg=fmt.tprintf("failed to seek writer to pos %d: %s", tdb.header.root_ei_pos, err.msg),
        }
    }

    if err := write_events_entry(writer, EventBlockEntry{new_id}); err.id != error.NONE {
        return error.Error{
            id=error.WRITE,
            msg=fmt.tprintf("failed to write entry to events block: %s", err.msg),
        }
    }

    updated_block_header := SimpleEventBlockHeader{
        id=tdb.root_events_header.id,
        entries_count=new_id,
    }

    if ok, err := tsv.seek_writer(writer, i64(tdb.header.root_ei_pos)); !ok {
        return error.Error{
            id=error.SEEK,
            msg=fmt.tprintf("failed to seek writer to pos %d: %s", tdb.header.root_ei_pos, err.msg),
        }
    }

    if err := write_events_header(writer, updated_block_header); err.id != error.NONE {
        return error.Error{
            id=error.WRITE,
            msg=fmt.tprintf("failed to write root events block header: %s", err.msg),
        }
    }

    tdb.root_events_header = updated_block_header

    // jump to end of event block, apply current count as offset and write frame data

    */
    return error.Error{
        id=error.NONE,
    }
}

/*
read :: proc(reader: tsv.Reader, dst: ^DB) -> error.Error {
    if ok, err := tsv.seek_reader(reader, 0); !ok {
        return error.Error{
            id=error.SEEK,
            msg=fmt.tprintf("failed to seek writer: %s", err.msg),
        }
    }

    head, err := read_header(reader)
    if err.id != error.NONE {
        return error.Error{
            id=err.id,
            msg=fmt.tprintf("failed to read header: %s", err.msg),
        }
    }

    dst.header = head

    if ok, err := tsv.seek_reader(reader, i64(dst.header.root_ei_pos)); !ok {
        return error.Error{
            id=error.SEEK,
            msg=fmt.tprintf("failed to seek: %s", err.msg),
        }
    }

    events_block_header: event.SimpleEventBlockHeader
    events_block_header, err = event.read_header(reader)
    if err.id != error.NONE {
        return error.Error{
            id=err.id,
            msg=fmt.tprintf("failed to read root events block header: %s", err.msg),
        }
    }

    dst.root_events_header = events_block_header

    return error.Error{
        id=error.NONE,
    }
}
*/
