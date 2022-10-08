package bintree

import "core:fmt"

BinTree :: ^BinNode

BinNode :: struct {
    key: int,
    left, right: ^BinNode,
}

create :: proc(item: int) -> BinTree {
    node := new(BinNode)
    node.key = item
    return node
}

insert :: proc(b: BinTree, key: int) -> BinTree {
    if b == nil {
        return create(key)
    }

    if key < b.key {
        b.left = insert(b.left, key)
    } else if key > b.key {
        b.right = insert(b.right, key)
    }

    return b
}

min_value_node :: proc(b: BinTree) -> ^BinNode {
    current: ^BinNode = b

    for current != nil && current.left != nil {
        current = current.left
    }

    return current
}

delete :: proc(b: BinTree, key: int) -> BinTree {
    if b == nil {
        return b
    }

    if key < b.key {
        b.left = delete(b.left, key)
    } else if key > b.key {
        b.right = delete(b.right, key)
    } else {
        if b.left == nil {
            temp: ^BinNode = b.right
            free(b)
            return temp
        } else if b.right == nil {
            temp: ^BinNode = b.left
            free(b)
            return temp
        }

        temp: ^BinNode = min_value_node(b.right)
        b.key = temp.key
        b.right = delete(b.right, temp.key)
    }

    return b
}

inorder :: proc(b: BinTree) {
    if b != nil {
        inorder(b.left)
        fmt.printf("%d \n", b.key)
        inorder(b.right)
    }
}

@private
is_leaf :: proc(b: BinNode) -> bool {
    return b.left == nil && b.right == nil
}

destroy :: proc(b: BinTree) {
    destroy_rec(b)
    free(b)
}

destroy_rec :: proc(n: ^BinNode) {
    if n.left != nil {
        destroy_rec(n.left)
    }

    if n.right != nil {
        destroy_rec(n.right)
    }
}
