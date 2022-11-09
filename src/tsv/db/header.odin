package db

import "core:fmt"
import "shared:bytes"
import "shared:tsv"
import "shared:typalias"
import "shared:tsv/error"
import "core:log"

@(private)
Header :: struct {
    magic:             uint32,
    root_ei_pos:       uint32,
}

@(private)
read_header :: proc(reader: tsv.Reader) -> (Header, error.Error) {
    data_to_read := [8]uint8{}
    if ok, err := tsv.read_sized(reader, data_to_read[:]); !ok {
        return Header{}, error.Error{
            id=err.id,
            msg=err.msg,
        }
    }

    return Header{
        magic=bytes.toUint32(data_to_read[:4]),
        root_ei_pos=bytes.toUint32(data_to_read[4:8]),
    }, error.Error{
        id=error.NONE,
    } 
}

@(private)
write_header :: proc(writer: tsv.Writer, head: Header, at_pos: i64 = 0) -> (bool, error.Error) {
    if ok, err := tsv.seek_writer(writer, at_pos); !ok {
        return false, error.Error{
            id=error.SEEK,
            msg=fmt.tprintf("failed to seek writer to pos %d: %s", at_pos, err.msg),
        }
    }

    dst := [8]uint8{}

    bytes.uint32ToA(head.magic, dst[:4])
    bytes.uint32ToA(head.root_ei_pos, dst[4:8])

    if ok, err := tsv.write_sized(writer, dst[:]); !ok {
        return false, error.Error{
            id=error.WRITE,
            msg=fmt.tprintf("failed to write: %s", err.msg),
        }
    }

    return true, error.Error{
        id=error.NONE,
    }
}

@(private)
alloc_header_to_bytes :: proc(head: Header) -> []u8 {
    b := make([]uint8, size_of(head))

    bytes.uint32ToA(head.magic, b[:4])
    bytes.uint32ToA(head.root_ei_pos, b[4:8])

    return b
}
