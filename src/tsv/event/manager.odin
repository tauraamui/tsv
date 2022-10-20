package event

Manager :: struct {
    cursor: u32,
}

new_manager :: proc() -> ^Manager {
    m := new(Manager)
    m.cursor = 0
    return m
}

