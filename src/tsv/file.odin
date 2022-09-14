package tsv

import "core:log"

@(private)
MAGIC :: 0x132BB6C

TimeSeriesVideo :: struct {
    header:            Header,
    root_events_block: EventsBlockHeader,
}

new :: proc() -> TimeSeriesVideo {
    return TimeSeriesVideo{
        header=Header{
            magic=MAGIC,
            root_ei_pos=size_of(Header{}),
        },
    }
}

load :: proc(r: Reader) -> TimeSeriesVideo {
    // ensure read at start
    seek_reader(r, 0)
    tsv := TimeSeriesVideo{
        header=read_header(r),
    }
    return tsv
}

store :: proc(w: Writer, tsv: TimeSeriesVideo) -> bool {
    if ok := seek_writer(w, 0); !ok {
        log.debug("ERROR: unable to seek writer to 0")
        return ok
    }

    return write_header(w, tsv.header)
}
