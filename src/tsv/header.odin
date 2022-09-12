package tsv

import "core:os"

FileHeader :: struct {
    magic:             u32,
    root_ei_pos:       u32,
}

write_header_to :: proc(fd: os.Handle, h: FileHeader) -> os.Errno {
    data_to_write := [8]u8{}

    u32ToBytes(h.magic, data_to_write[:4])
    u32ToBytes(h.root_ei_pos, data_to_write[4:8])

    n, err := os.write(fd, data_to_write[:8])
    if err != os.ERROR_NONE {
        return err
    }

    return os.ERROR_NONE
}

read_header :: proc(fd: os.Handle) -> FileHeader {
    data_to_read := [8]u8{}
    os.read(fd, data_to_read[:8])
    return FileHeader{
        magic=bytesToU32(data_to_read[:4]),
        root_ei_pos=bytesToU32(data_to_read[4:8]),
    }
}

EventBlockHeader :: struct {
    id:   u32,
    size: u32,
    start_time: u32,
    elapsed_duration: u32,
}

write_empty_event_block :: proc(fd: os.Handle, e: EventBlockHeader) -> os.Errno {
    data := make([]u8, size_of(e)+e.size)
    defer delete(data)

    u32ToBytes(e.id, data[:4])
    u32ToBytes(size_of(e)+e.size, data[4:8])
    u32ToBytes(e.start_time, data[8:12])
    u32ToBytes(e.elapsed_duration, data[12:16])

    _, err := os.write(fd, data)
    if err != os.ERROR_NONE {
        return err
    }

    return os.ERROR_NONE
}

u32ToBytes :: proc(n: u32, d: []u8) {
    assert(len(d) == 4)
    d[0] = u8(n)
    d[1] = u8(n >> 8)
    d[2] = u8(n >> 16)
    d[3] = u8(n >> 24)
}

bytesToU32 :: proc(d: []u8) -> u32 {
    assert(len(d) == 4)
    return u32(d[0]) | u32(d[1])<<8 | u32(d[2])<<16 | u32(d[3])<<24
}
