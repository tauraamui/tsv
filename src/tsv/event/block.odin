package event

import "core:fmt"
import "shared:bytes"
import "core:os"
import "core:time"
import "shared:tsv"
import "shared:tsv/error"

EventsBlockHeader :: struct {
    id:         uint32,
    max_cap:    uint32,
    size:       uint32,
    duration:   uint32,
    fps:        uint32,
    frame_size: uint32,
}

@(private)
read_events_block_header :: proc(r: tsv.Reader) -> (EventsBlockHeader, error.Error) {
    dat := [24]uint8{}
    if ok, err := tsv.read_sized(r, dat[:]); !ok {
        return EventsBlockHeader{}, error.Error{
            id=error.READ,
            msg=fmt.tprintf("failed to read: %s", err.msg),
        }
    }

    return EventsBlockHeader{
        id=bytes.toUint32(dat[:4]),
        max_cap=bytes.toUint32(dat[4:8]),
        size=bytes.toUint32(dat[8:12]),
        duration=bytes.toUint32(dat[12:16]),
        fps=bytes.toUint32(dat[16:20]),
        frame_size=bytes.toUint32(dat[20:24]),
    }, error.Error{
        id=error.NONE,
    }
}

@(private)
write_events_block_header :: proc(writer: tsv.Writer, head: EventsBlockHeader) -> error.Error {
    dst := [24]uint8{}

    bytes.uint32ToA(head.id, dst[:4])
    bytes.uint32ToA(head.max_cap, dst[4:8])
    bytes.uint32ToA(head.size, dst[8:12])
    bytes.uint32ToA(head.duration, dst[12:16])
    bytes.uint32ToA(head.fps, dst[16:20])
    bytes.uint32ToA(head.frame_size, dst[20:24])

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

@(private) write_events_block_alloc :: proc(writer: tsv.Writer, size: uint32) -> error.Error {
    if ok, err := tsv.seek_writer(writer, i64(size), os.SEEK_END); !ok {
        return error.Error{
            id=error.SEEK,
            msg=fmt.tprintf("failed to seek to end of file: %s", err.msg),
        }
    }

    if size % 1024 > 0 {
        return error.Error{
            id=error.WRITE,
            msg=fmt.tprintf("size (%d) must be multiple of 1024", size),
        }
    }

    b := make([]uint8, 1024)
    defer delete(b)

    i := size / 1024
    for j := i; j > 0; j -= 1 {
        if j % 3 > 0 {
            time.sleep(time.Microsecond)
        }
        if ok, err := tsv.write_sized(writer, b); !ok {
            return error.Error{
                id=error.WRITE,
                msg=fmt.tprintf("failed to write event block allocation: %s", err.msg),
            }
        }
    }

    return error.Error{
        id=error.NONE,
    }
}
