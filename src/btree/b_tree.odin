package btree

DEFAULT_MIN_ITEMS :: 128

BTree :: ^BTNode

Item :: struct {
    key: string,
    value: any,
}

BTNode :: struct {
    minItems, maxItems: int,
    items: []Item,
    children: []BTNode,
}

create :: proc(min: int = DEFAULT_MIN_ITEMS) -> BTree {
    node := new(BTNode)
    node.minItems = min
    node.maxItems = min * 2
    return node
}

insert :: proc(b: BTree, key: string, value: any) {
    item := Item{
        key = key,
        value = value,
    }

    insertionIndex, nodeToInsertIn, ancestorsIndexes := find_key(b, item.key, false)
}

@private
find_key :: proc(b: BTree, key: string, exact: bool) -> (int, BTree, []int) {
    // n := 
    return -1, nil, nil
}

@private
is_leaf :: proc(b: BTree) -> bool {
    return len(b.children) == 0
}

destroy :: proc(b: BTree) {
    free(b)
}
