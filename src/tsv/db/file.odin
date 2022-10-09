package db

import "core:fmt"
import "shared:tsv"

@(private)
MAGIC :: 0x132BB6C

DB :: struct {
    seeker_reader:            tsv.Reader,
    seeker_writer:            tsv.Writer,
    header:                   Header,
    root_events_block_header: EventsBlockHeader,
}

create :: proc() -> DB {
    return DB{
        header=Header{
            magic=MAGIC,
            root_ei_pos=size_of(Header{}),
        },
        root_events_block_header=EventsBlockHeader{
            id=1,
            size=1024,
            duration=0,
            fps=0,
            frame_size=0,
        },
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

    if err := write_events_block_header(writer, tdb.root_events_block_header); err.id != tsv.ERROR_NONE {
        return tsv.Error{
            id=tsv.ERROR_WRITE,
            msg=fmt.tprintf("failed to write root events block header: %s", err.msg),
        }
    }

    if err := write_events_block_alloc(writer, tdb.root_events_block_header.size); err.id != tsv.ERROR_NONE {
        return tsv.Error{
            id=tsv.ERROR_WRITE,
            msg=fmt.tprintf("unable to write root events block: %s", err.msg),
        }
    }

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

    events_block_header: EventsBlockHeader
    events_block_header, err = read_events_block_header(reader)
    if err.id != tsv.ERROR_NONE {
        return tsv.Error{
            id=err.id,
            msg=fmt.tprintf("failed to read root events block header: %s", err.msg),
        }
    }

    dst.root_events_block_header = events_block_header

    return tsv.Error{
        id=tsv.ERROR_NONE,
    }
}
