package tsv

import "core:log"

@(private)
MAGIC :: 0x132BB6C

TimeSeriesVideo :: struct {
    header:            Header,
    root_events_block_header: EventsBlockHeader,
}

new :: proc() -> TimeSeriesVideo {
    return TimeSeriesVideo{
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

load :: proc(r: Reader) -> (TimeSeriesVideo, bool) {
    // ensure read at start
    seek_reader(r, 0)
    head, ok := read_header(r)
    if !ok {
        return TimeSeriesVideo{}, false
    }
    tsv := TimeSeriesVideo{
        header=head,
    }
    seek_reader(r, i64(tsv.header.root_ei_pos))
    events_block_header: EventsBlockHeader
    events_block_header, ok = read_events_block_header(r)
    if !ok {
        return TimeSeriesVideo{}, false
    }
    tsv.root_events_block_header = events_block_header
    return tsv, true
}

store :: proc(w: Writer, tsv: TimeSeriesVideo) -> bool {
    if ok := seek_writer(w, 0); !ok {
        log.debug("ERROR: unable to seek writer to 0")
        return ok
    }

    if ok := write_header(w, tsv.header); !ok {
        return ok
    }

    if ok := seek_writer(w, i64(tsv.header.root_ei_pos)); !ok {
        return ok
    }

    if ok := write_events_block_header(w, tsv.root_events_block_header); !ok {
        return ok
    }

    return true
}
