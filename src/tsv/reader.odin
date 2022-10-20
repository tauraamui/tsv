package tsv

import "core:log"
import "core:os"
import "shared:tsv/error"

ExternalError :: struct {
	id:  error.ID,
	msg: string,
}

SeekFn :: proc(_: rawptr, _: i64, _: int) -> (i64, ExternalError)
ReaderFn :: proc(_: rawptr, _: []byte) -> (int, ExternalError)

Reader :: struct {
	seek_fn:        SeekFn,
	reader_fn:      ReaderFn,
	reader_context: rawptr,
}

make_reader :: proc(reader_fn: ReaderFn, seek_fn: SeekFn, reader_context: rawptr) -> Reader {
    return Reader{reader_context=reader_context, reader_fn=reader_fn, seek_fn=seek_fn}
}

seek_reader :: proc(reader: Reader, offset: i64, whence := os.SEEK_SET) -> (bool, ExternalError) {
	_, err := reader.seek_fn(reader.reader_context, offset, whence)
	if err.id == 0 {
		return true, ExternalError{}
	}
	return false, err
}

read_sized :: proc(reader: Reader, data: []u8) -> (bool, ExternalError) {
	size := len(data)
	n := 0
	ok := true
	err: ExternalError
	for n < size && ok {
		read: int

		read, err = reader.reader_fn(reader.reader_context, data[n:])
		if read == 0 && err.id == error.NONE {
			return false, ExternalError{
				id=error.READING_EMPTY,
				msg="unable to read data from empty loc",
			}
		}

		ok = err.id == 0

		n += read
	}

	if n >= size {
		ok = true
	}

	if !ok {
		return false, err
	}

	return ok, ExternalError{}
}
