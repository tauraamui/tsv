package tsv

// , offset: i64, whence: int) -> (i64, Errno)
SeekFn :: proc(_: rawptr, _: i64, _: int) -> (i64, int)
ReaderFn :: proc(_: rawptr, _: []byte) -> (int, int)

Reader :: struct {
	seek_fn:        SeekFn,
	reader_fn:      ReaderFn,
	reader_context: rawptr,
}

make_reader :: proc(reader_fn: ReaderFn, seek_fn: SeekFn, reader_context: rawptr) -> Reader {
    return Reader{reader_context=reader_context, reader_fn=reader_fn, seek_fn=seek_fn}
}

seek :: proc(reader: ^Reader, offset: i64) -> (ok: bool) {
	ok = true
	_, err_code := reader.seek_fn(reader.reader_context, offset, 0)
	ok = err_code == 0
	return
}

read_sized :: proc(reader: ^Reader, data: []u8) -> (ok: bool) {
	ok = true
	size := len(data)
	n := 0

	for n < size && ok {
		read: int
		err_code: int

		read, err_code = reader.reader_fn(reader.reader_context, data[n:])

		ok = err_code == 0

		n += read
	}

	if n >= size {
		ok = true
	}

	return
}
