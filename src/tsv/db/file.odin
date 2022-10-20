package db

import "core:fmt"
import "shared:tsv"
import "shared:tsv/frame"
import "shared:tsv/event"
import "shared:tsv/error"

@(private)
MAGIC :: 0x132BB6C

@(private)
ROOT_HEADER_POS :: 0

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

    if err.id != error.NONE && err.id != error.EARLY_EOF {
        return Header{}, err
    }

    if err.id == error.EARLY_EOF {
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
    return error.Error{
        id=error.NONE,
    }
}
