package tsv

uint8   :: u8
uint16  :: u16
uint32  :: u32

@(private="file")
DEFAULT_FRAME_SIZE :: 1024 * 1024

Frame :: struct {
    size: uint32,
}

new_frame :: proc() -> Frame {
    return Frame{
        size=DEFAULT_FRAME_SIZE,
    }
}
