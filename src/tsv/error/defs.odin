package error

Error :: struct {
    id:  ID,
    msg: string,
}

ID :: distinct i32

NONE:  ID: 0
SEEK:  ID: 1
READ:  ID: 2
WRITE: ID: 3
