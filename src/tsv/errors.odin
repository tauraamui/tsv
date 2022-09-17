package tsv

Error :: struct {
    id:  ErrID,
    msg: string,
}

ErrID :: distinct i32

ERROR_NONE:  ErrID: 0
ERROR_SEEK:  ErrID: 1
ERROR_READ:  ErrID: 2
ERROR_WRITE: ErrID: 3
