package tsv

import "core:sync"
import "core:log"

WriterFn :: proc(_: rawptr, _: []byte) -> (int, int)

@(private)
Writer :: struct {
	seek_fn:        SeekFn,
	writer_fn:      WriterFn,
	writer_context: rawptr,
}

make_writer :: proc(writer_fn: WriterFn, seek_fn: SeekFn, writer_context: rawptr) -> Writer {
	writer := Writer {
		writer_context = writer_context,
		writer_fn      = writer_fn,
		seek_fn        = seek_fn,
	}
	return writer
}

@(private)
seek_writer :: proc(writer: Writer, offset: i64) -> (ok: bool) {
	log.debug("seeking writer to", offset)

	ok = true
	_, err_code := writer.seek_fn(writer.writer_context, offset, 0)
	ok = err_code == 0
	return
}

@(private)
write_sized :: proc(writer: Writer, data: []byte) -> bool {
    written, err := writer.writer_fn(writer.writer_context, data)

    if (err != 0) {
        return false
    }

    return true
}
