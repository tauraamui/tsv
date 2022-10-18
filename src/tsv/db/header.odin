package db

import "core:fmt"
import "shared:bytes"
import "shared:tsv"
import "shared:typalias"

@(private)
Header :: struct {
    magic:             uint32,
    root_ei_pos:       uint32,
}

@(private)
read_header :: proc(reader: tsv.Reader) -> (Header, tsv.Error) {
    data_to_read := [8]uint8{}
    if ok, err := tsv.read_sized(reader, data_to_read[:]); !ok {
        return Header{}, tsv.Error{
            id=tsv.ERROR_READ,
            msg=fmt.tprintf("failed to read: %s", err.msg),
        }
    }

    return Header{
        magic=bytes.toUint32(data_to_read[:4]),
        root_ei_pos=bytes.toUint32(data_to_read[4:8]),
    }, tsv.Error{
        id=tsv.ERROR_NONE,
    } 
}

@(private)
write_header :: proc(writer: tsv.Writer, head: Header, at_pos: i64 = 0) -> (bool, tsv.Error) {
    if ok, err := tsv.seek_writer(writer, at_pos); !ok {
        return false, tsv.Error{
            id=tsv.ERROR_SEEK,
            msg=fmt.tprintf("failed to seek writer to pos %d: %s", ROOT_HEADER_POS, err.msg),
        }
    }

    dst := [8]uint8{}

    bytes.uint32ToA(head.magic, dst[:4])
    bytes.uint32ToA(head.root_ei_pos, dst[4:8])

    if ok, err := tsv.write_sized(writer, dst[:]); !ok {
        return false, tsv.Error{
            id=tsv.ERROR_WRITE,
            msg=fmt.tprintf("failed to write: %s", err.msg),
        }
    }

    return true, tsv.Error{
        id=tsv.ERROR_NONE,
    }
}

@(private)
alloc_header_to_bytes :: proc(head: Header) -> []u8 {
    b := make([]uint8, size_of(head))

    bytes.uint32ToA(head.magic, b[:4])
    bytes.uint32ToA(head.root_ei_pos, b[4:8])

    return b
}
