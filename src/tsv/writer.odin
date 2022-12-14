package tsv

import "core:sync"
import "core:log"
import "core:os"
import "shared:tsv/error"

WriterFn :: proc(_: rawptr, _: []byte) -> (int, ExternalError)

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

seek_writer :: proc(writer: Writer, offset: i64, whence := os.SEEK_SET) -> (bool, ExternalError) {
	log.debug("seeking writer to", offset)
	_, err := writer.seek_fn(writer.writer_context, offset, whence)
	if err.id == 0 {
		return true, ExternalError{
			id=error.NONE,
		}
	}
	return false, err
}

write_sized :: proc(writer: Writer, data: []byte) -> (bool, ExternalError) {
    _, err := writer.writer_fn(writer.writer_context, data)
	if err.id == 0 {
		return true, ExternalError{
			id=error.NONE,
		}
	}
    return false, err
}
