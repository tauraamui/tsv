package tsv

import "core:sync"
import "core:log"
import "core:os"

WriterFn :: proc(_: rawptr, _: []byte) -> (int, ExternalError)

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
seek_writer :: proc(writer: Writer, offset: i64, whence := os.SEEK_CUR) -> (bool, ExternalError) {
	log.debug("seeking writer to", offset)
	_, err := writer.seek_fn(writer.writer_context, offset, whence)
	if err.id == 0 {
		return true, ExternalError{
			id=ERROR_NONE,
		}
	}
	return false, err
}

@(private)
write_sized :: proc(writer: Writer, data: []byte) -> (bool, ExternalError) {
    _, err := writer.writer_fn(writer.writer_context, data)
	if err.id == 0 {
		return true, ExternalError{
			id=ERROR_NONE,
		}
	}
    return false, err
}
