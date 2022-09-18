package tsv

import "core:log"
import "core:fmt"

@(private)
MAGIC :: 0x132BB6C

@(private)
TimeSeriesVideo :: struct {
    seeker_reader:            Reader,
    seeker_writer:            Writer,
    header:                   Header,
    root_events_block_header: EventsBlockHeader,
}

new :: proc(r: Reader, w: Writer) -> TimeSeriesVideo {
    return TimeSeriesVideo{
        seeker_reader=r,
        seeker_writer=w,
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

create :: proc(tsv: TimeSeriesVideo) -> Error {
    if ok, err := seek_writer(tsv.seeker_writer, 0); !ok {
        return Error{
            id=ERROR_SEEK,
            msg=fmt.tprintf("failed to seek writer: %s", err.msg),
        }
    }

    if ok, err := write_header(tsv.seeker_writer, tsv.header); !ok {
        return Error{
            id=ERROR_WRITE,
            msg=fmt.tprintf("failed to write header: %s", err.msg),
        }
    }

    if ok, err := seek_writer(tsv.seeker_writer, i64(tsv.header.root_ei_pos)); !ok {
        return Error{
            id=ERROR_SEEK,
            msg=fmt.tprintf("failed to seek writer to pos %d: %s", tsv.header.root_ei_pos, err.msg),
        }
    }

    if err := write_events_block_header(tsv.seeker_writer, tsv.root_events_block_header); err.id != ERROR_NONE {
        return Error{
            id=ERROR_WRITE,
            msg=fmt.tprintf("failed to write root events block header: %s", err.msg),
        }
    }

    return Error{
        id=ERROR_NONE,
    }
}

open :: proc(tsv: ^TimeSeriesVideo) -> Error {
    if ok, err := seek_reader(tsv.seeker_reader, 0); !ok {
        return Error{
            id=ERROR_SEEK,
            msg=fmt.tprintf("failed to seek reader: %s", err.msg),
        }
    }

    head, err := read_header(tsv.seeker_reader)
    if err.id != ERROR_NONE {
        return Error{
            id=err.id,
            msg=fmt.tprintf("failed to read header: %s", err.msg),
        }
    }

    tsv.header = head

    log.debug("READ HEADER")
    if ok, err := seek_reader(tsv.seeker_reader, i64(tsv.header.root_ei_pos)); !ok {
        return Error{
            id=ERROR_SEEK,
            msg=fmt.tprintf("failed to seek: %s", err.msg),
        }
    }

    events_block_header: EventsBlockHeader
    events_block_header, err = read_events_block_header(tsv.seeker_reader)
    if err.id != ERROR_NONE {
        return Error{
            id=err.id,
            msg=fmt.tprintf("failed to read root events block header: %s", err.msg),
        }
    }

    tsv.root_events_block_header = events_block_header

    return Error{
        id=ERROR_NONE,
    }
}

// open :: proc(r: Reader) -> TimeSeriesVideo {
//     default := new()
//     seek_reader(r, 0)
//     head, ok := read_header(r)
//     if !ok {
//         return default
//     }

//     default.header = head

//     seek_reader(r, default.header.root_ei_pos)
//     events_block_header: EventsBlockHeader
//     events_block_header, ok = read_events_block_header(r)

//     return default
// }

// load :: proc(r: Reader) -> (TimeSeriesVideo, bool) {
//     // ensure read at start
//     seek_reader(r, 0)
//     head, ok := read_header(r)
//     if !ok {
//         return TimeSeriesVideo{}, false
//     }
//     tsv := TimeSeriesVideo{
//         header=head,
//     }
//     seek_reader(r, i64(tsv.header.root_ei_pos))
//     events_block_header: EventsBlockHeader
//     events_block_header, ok = read_events_block_header(r)
//     if !ok {
//         return TimeSeriesVideo{}, false
//     }
//     tsv.root_events_block_header = events_block_header
//     return tsv, true
// }

// store :: proc(w: Writer, tsv: TimeSeriesVideo) -> bool {
//     if ok := seek_writer(w, 0); !ok {
//         log.debug("ERROR: unable to seek writer to 0")
//         return ok
//     }

//     if ok := write_header(w, tsv.header); !ok {
//         return ok
//     }

//     if ok := seek_writer(w, i64(tsv.header.root_ei_pos)); !ok {
//         return ok
//     }

//     if ok := write_events_block_header(w, tsv.root_events_block_header); !ok {
//         return ok
//     }

//     return true
// }
