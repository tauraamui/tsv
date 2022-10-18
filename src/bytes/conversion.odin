package bytes

import "shared:typalias"

uint8 :: typalias.uint8
uint16  :: typalias.uint16
uint32  :: typalias.uint32

uint8ToA :: proc(n: uint8, d: []uint8) {
    assert(len(d) == 1)
    d[0] = u8(n)
}

uint16ToA :: proc(n: uint16, d: []uint8) {
    assert(len(d) == 2)
    d[0] = u8(n)
    d[1] = u8(n >> 8)
}

uint32ToA :: proc(n: uint32, d: []uint8) {
    assert(len(d) == 4)
    d[0] = u8(n)
    d[1] = u8(n >> 8)
    d[2] = u8(n >> 16)
    d[3] = u8(n >> 24)
}

toUint8 :: proc(d: []uint8) -> uint8 {
    assert(len(d) == 1)
    return u8(d[0])
}

toUint16 :: proc(d: []uint8) -> uint16 {
    assert(len(d) == 2)
    return u16(d[0]) | u16(d[1])<<8
}

toUint32 :: proc(d: []uint8) -> uint32 {
    assert(len(d) == 4)
    return u32(d[0]) | u32(d[1])<<8 | u32(d[2])<<16 | u32(d[3])<<24
}