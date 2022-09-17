package tsv

import "core:fmt"

@(private)
Header :: struct {
    magic:             uint32,
    root_ei_pos:       uint32,
}

@(private)
read_header :: proc(reader: Reader) -> (Header, Error) {
    data_to_read := [8]uint8{}
    if ok, err := read_sized(reader, data_to_read[:]); !ok {
        return Header{}, Error{
            id=ERROR_READ,
            msg=fmt.tprintf("failed to read: %s", err.msg),
        }
    }

    return Header{
        magic=bytesToUint32(data_to_read[:4]),
        root_ei_pos=bytesToUint32(data_to_read[4:8]),
    }, Error{
        id=ERROR_NONE,
    } 
}

@(private)
write_header :: proc(writer: Writer, head: Header) -> (bool, Error) {
    dst := [8]uint8{}

    uint32ToBytes(head.magic, dst[:4])
    uint32ToBytes(head.root_ei_pos, dst[4:8])

    if ok, err := write_sized(writer, dst[:]); !ok {
        return false, Error{
            id=ERROR_WRITE,
            msg=fmt.tprintf("failed to write: %s", err.msg),
        }
    }

    return true, Error{
        id=ERROR_NONE,
    }
}

@(private)
alloc_header_to_bytes :: proc(head: Header) -> []u8 {
    b := make([]uint8, size_of(head))

    uint32ToBytes(head.magic, b[:4])
    uint32ToBytes(head.root_ei_pos, b[4:8])

    return b
}

uint8ToBytes :: proc(n: uint8, d: []uint8) {
    assert(len(d) == 1)
    d[0] = u8(n)
}

uint16ToBytes :: proc(n: uint16, d: []uint8) {
    assert(len(d) == 2)
    d[0] = u8(n)
    d[1] = u8(n >> 8)
}

uint32ToBytes :: proc(n: uint32, d: []uint8) {
    assert(len(d) == 4)
    d[0] = u8(n)
    d[1] = u8(n >> 8)
    d[2] = u8(n >> 16)
    d[3] = u8(n >> 24)
}

bytesToUint8 :: proc(d: []uint8) -> uint8 {
    assert(len(d) == 1)
    return u8(d[0])
}

bytesToUint16 :: proc(d: []uint8) -> uint16 {
    assert(len(d) == 2)
    return u16(d[0]) | u16(d[1])<<8
}

bytesToUint32 :: proc(d: []uint8) -> uint32 {
    assert(len(d) == 4)
    return u32(d[0]) | u32(d[1])<<8 | u32(d[2])<<16 | u32(d[3])<<24
}
