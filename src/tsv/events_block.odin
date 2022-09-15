package tsv

EventsBlockHeader :: struct {
    id:         uint32,
    size:       uint32,
    duration:   uint32,
    fps:        uint32,
    frame_size: uint32,
}

@(private)
read_events_block_header :: proc(r: Reader) -> (EventsBlockHeader, bool) {
    dat := [20]uint8{}
    if ok := read_sized(r, dat[:]); !ok {
        return EventsBlockHeader{}, ok
    }

    return EventsBlockHeader{
        id=bytesToUint32(dat[:4]),
        size=bytesToUint32(dat[4:8]),
        duration=bytesToUint32(dat[8:12]),
        fps=bytesToUint32(dat[12:16]),
        frame_size=bytesToUint32(dat[16:20]),
    }, true
}

@(private)
write_events_block_header :: proc(writer: Writer, head: EventsBlockHeader) -> bool {
    dst := [20]uint8{}

    uint32ToBytes(head.id, dst[:4])
    uint32ToBytes(head.size, dst[4:8])
    uint32ToBytes(head.duration, dst[8:12])
    uint32ToBytes(head.fps, dst[12:16])
    uint32ToBytes(head.frame_size, dst[16:20])

    return write_sized(writer, dst[:])
}
