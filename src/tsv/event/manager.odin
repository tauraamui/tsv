package event

import "shared:tsv"

Manager :: struct {
    writer: tsv.Writer,
    reader: tsv.Reader,
    cursor: u32,
}

new_manager :: proc(writer: tsv.Writer, reader: tsv.Reader) -> ^Manager {
    m := new(Manager)
    m.writer = writer
    m.reader = reader
    m.cursor = 0

    resolve_blocks(m)

    return m
}

close :: proc(man: ^Manager) {
    free(man)
}

@(private)
resolve_blocks :: proc(man: ^Manager) {

}

