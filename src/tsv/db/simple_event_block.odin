package db

import "core:fmt"
import "shared:tsv"

MAX_EVENT_SIZE :: 1024

SimpleEventBlockHeader :: struct {
    id:             u32,
    entries_count:  u32,
}

EventBlockEntry :: struct {
    frame_id: u32,
}

read_events_header :: proc(reader: tsv.Reader) -> (SimpleEventBlockHeader, tsv.Error) {
    dat := [8]uint8{}
    if ok, err := tsv.read_sized(reader, dat[:]); !ok {
        return SimpleEventBlockHeader{}, tsv.Error{
            id=tsv.ERROR_READ,
            msg=fmt.tprintf("failed to read: %s", err.msg),
        }
    }

    return SimpleEventBlockHeader{
        id=bytesToUint32(dat[:4]),
        entries_count=bytesToUint32(dat[4:8]),
    }, tsv.Error{
        id=tsv.ERROR_NONE,
    }
}

write_events_header :: proc(writer: tsv.Writer, evt: SimpleEventBlockHeader, at_pos: i64) -> tsv.Error {
    if ok, err := tsv.seek_writer(writer, at_pos); !ok {
        return tsv.Error{
            id=tsv.ERROR_SEEK,
            msg=fmt.tprintf("failed to seek writer to pos %d: %s", at_pos, err.msg),
        }
    }

    dst := [8]uint8{}

    uint32ToBytes(evt.id, dst[:4])
    uint32ToBytes(evt.entries_count, dst[4:8])


    if ok, err := tsv.write_sized(writer, dst[:]); !ok {
        return tsv.Error{
            id=tsv.ERROR_WRITE,
            msg=fmt.tprintf("failed to write events block header: %s", err.msg),
        }
    }

    return tsv.Error{
        id=tsv.ERROR_NONE,
    }
}

write_events_entry :: proc(writer: tsv.Writer, evt: EventBlockEntry) -> tsv.Error {
    dst := [4]uint8{}

    uint32ToBytes(evt.frame_id, dst[:4])

    if ok, err := tsv.write_sized(writer, dst[:]); !ok {
        return tsv.Error{
            id=tsv.ERROR_WRITE,
            msg=fmt.tprintf("failed to write events block header: %s", err.msg),
        }
    }

    return tsv.Error{
        id=tsv.ERROR_NONE,
    }
}

