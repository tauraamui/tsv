package tsv

import "core:os"

Header :: struct {
    magic:             u32,
    start_timestamp:   u32,
    elapsed_duration:  u32,
    root_ei_pos:       u32,
}

write_header_to :: proc(fd: os.Handle, h: Header) -> os.Errno {
    data_to_write := [16]u8{}

    u32ToBytes(h.magic, data_to_write[:4])
    u32ToBytes(h.start_timestamp, data_to_write[4:8])
    u32ToBytes(h.elapsed_duration, data_to_write[8:12])
    u32ToBytes(h.root_ei_pos, data_to_write[12:16])

    n, err := os.write(fd, data_to_write[:16])
    if err != os.ERROR_NONE {
        return err
    }

    return os.ERROR_NONE
}

EventBlock :: struct {
    id:   u32,
    size: u32,
}

allocate_event_block :: proc(fd: os.Handle, e: EventBlock) -> os.Errno {
    max, err := os.file_size(fd)
    if err != os.ERROR_NONE {
        return err
    }
    os.seek(fd, max, 0)

    data := make([]u8, e.size)
    defer delete(data)
    _, err = os.write(fd, data)
    if err != os.ERROR_NONE {
        return err
    }

    return os.ERROR_NONE
}

u32ToBytes :: proc(n: u32, d: []u8) -> []u8 {
    assert(len(d) == 4)
    d[0] = u8(n)
    d[1] = u8(n >> 8)
    d[2] = u8(n >> 16)
    d[3] = u8(n >> 24)
    return d
}
