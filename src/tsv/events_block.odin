package tsv

EventsBlockHeader :: struct {
    id:         uint32,
    max_cap:    uint32,
    size:       uint32,
    duration:   uint32,
    fps:        uint32,
    frame_size: uint32,
}

@(private)
read_events_block_header :: proc(r: Reader) -> (EventsBlockHeader, bool) {
    dat := [24]uint8{}
    if ok := read_sized(r, dat[:]); !ok {
        return EventsBlockHeader{}, ok
    }

    return EventsBlockHeader{
        id=bytesToUint32(dat[:4]),
        max_cap=bytesToUint32(dat[4:8]),
        size=bytesToUint32(dat[8:12]),
        duration=bytesToUint32(dat[12:16]),
        fps=bytesToUint32(dat[16:20]),
        frame_size=bytesToUint32(dat[20:24]),
    }, true
}

@(private)
write_events_block_header :: proc(writer: Writer, head: EventsBlockHeader) -> bool {
    dst := [24]uint8{}

    uint32ToBytes(head.id, dst[:4])
    uint32ToBytes(head.max_cap, dst[4:8])
    uint32ToBytes(head.size, dst[8:12])
    uint32ToBytes(head.duration, dst[12:16])
    uint32ToBytes(head.fps, dst[16:20])
    uint32ToBytes(head.frame_size, dst[20:24])

    return write_sized(writer, dst[:])
}
