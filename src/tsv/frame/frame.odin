package frame

import "core:math/rand"
import "core:fmt"
import "shared:typalias"

uint8 :: typalias.uint8
uint16  :: typalias.uint16
uint32  :: typalias.uint32

@(private)
pixel :: struct {
    R, G, B: uint8,
}

Frame :: struct {
    width, height: int,
    data: []pixel,
}

create :: proc(w, h: int) -> Frame {
    return Frame{
        width = w,
        height = h,
        data = make([]pixel, w * h),
    }
}

alloc_bytes :: proc(f: Frame) -> []byte {
    b := make([]byte, (f.width * f.height) * 3)
    for pix, i in f.data {
        b[i]   = pix.R
        b[i+1] = pix.G
        b[i+2] = pix.B
    }
    return b
}

fill_random :: proc(f: Frame, seed: u64 = 30) {
    rand.set_global_seed(seed)
    for y := 0; y < f.height; y += 1 {
        for x := 0; x < f.width; x += 1 {
            pos := (y * f.width) + x
            pix := f.data[pos]
            pix.R = uint8(rand.int_max(255))
            pix.G = uint8(rand.int_max(255))
            pix.B = uint8(rand.int_max(255))
            f.data[pos] = pix
        }
    }
}

output :: proc(f: Frame) {
    for y := 0; y < f.height; y += 1 {
        for x := 0; x < f.width; x += 1 {
            pos := (y * f.width) + x
            pix := f.data[pos]
            fmt.printf("X: %d, Y: %d -> RGB(%d,%d,%d)\n", x, y, pix.R, pix.G, pix.B)
        }
    }
}

destroy :: proc(f: Frame) {
    delete(f.data)
}


