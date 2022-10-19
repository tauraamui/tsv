package event

import "core:fmt"
import "shared:bytes"
import "shared:tsv"
import "shared:typalias"
import "shared:tsv/error"

uint8 :: typalias.uint8
uint16  :: typalias.uint16
uint32  :: typalias.uint32

MAX_EVENT_SIZE :: 1024

SimpleEventBlockHeader :: struct {
    id:             u32,
    entries_count:  u32,
}

EventBlockEntry :: struct {
    frame_id: u32,
}

read_header :: proc(reader: tsv.Reader) -> (SimpleEventBlockHeader, error.Error) {
    dat := [8]uint8{}
    if ok, err := tsv.read_sized(reader, dat[:]); !ok {
        return SimpleEventBlockHeader{}, error.Error{
            id=error.READ,
            msg=fmt.tprintf("failed to read: %s", err.msg),
        }
    }

    return SimpleEventBlockHeader{
        id=bytes.toUint32(dat[:4]),
        entries_count=bytes.toUint32(dat[4:8]),
    }, error.Error{
        id=error.NONE,
    }
}

write_header :: proc(writer: tsv.Writer, evt: SimpleEventBlockHeader, at_pos: i64) -> error.Error {
    if ok, err := tsv.seek_writer(writer, at_pos); !ok {
        return error.Error{
            id=error.SEEK,
            msg=fmt.tprintf("failed to seek writer to pos %d: %s", at_pos, err.msg),
        }
    }

    dst := [8]uint8{}

    bytes.uint32ToA(evt.id, dst[:4])
    bytes.uint32ToA(evt.entries_count, dst[4:8])


    if ok, err := tsv.write_sized(writer, dst[:]); !ok {
        return error.Error{
            id=error.WRITE,
            msg=fmt.tprintf("failed to write events block header: %s", err.msg),
        }
    }

    return error.Error{
        id=error.NONE,
    }
}

write_entry :: proc(writer: tsv.Writer, evt: EventBlockEntry) -> error.Error {
    dst := [4]uint8{}

    bytes.uint32ToA(evt.frame_id, dst[:4])

    if ok, err := tsv.write_sized(writer, dst[:]); !ok {
        return error.Error{
            id=error.WRITE,
            msg=fmt.tprintf("failed to write events block header: %s", err.msg),
        }
    }

    return error.Error{
        id=error.NONE,
    }
}

