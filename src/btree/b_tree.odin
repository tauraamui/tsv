package btree

import "core:log"

@(private)
MAX_KEYS :: 1024

BTree :: ^BTNode

BTNode :: struct {
    is_leaf: bool,
    num_keys: int,
    keys: [MAX_KEYS]int,
    kids: [MAX_KEYS + 1]^BTNode,
}

create :: proc() -> BTree {
    node := new(BTNode)
    node.is_leaf = true
    node.num_keys = 0
    return node
}

destroy :: proc(b: BTree) {
    if !b.is_leaf {
        for i := 0; i < len(b.kids); i +=1 {
            if d := b.kids[i]; d != nil {
                destroy(b.kids[i])
            } else {
                log.debug("found nil kid")
            }
        }
    }
    free(b)
}

search :: proc(b: BTree, key: int) -> int {
    pos: int

    /* have to check for empty tree */
    if b.num_keys == 0 {
        return 0
    }

    /* look for smallest position that key fits below */
    pos = search_key(b.num_keys, b.keys[:], key)

    if pos < b.num_keys && b.keys[pos] == key {
        return 1
    }

    return int(!b.is_leaf && bool(search(b.kids[pos], key)))
}

insert :: proc(b: BTree, key: int) {
    output_log := false
    // output_log := key >= 525817
    if output_log {
        log.debug("------------- BEGIN INSERTING -------------")
    }

    median: int
    b2 := insert_key(b, key, &median)
    if b2 != nil {
        /* basic issue here is that we are at the root */
        /* so if we split, we have to make a new root */
        b1 := new_clone(b^)

        /* make root point to b1 and b2 */
        b.num_keys = 1
        b.is_leaf = false
        b.keys[0] = median
        b.kids[0] = b1
        b.kids[1] = b2
    }
    if output_log {
        log.debug("------------- END INSERTING -------------")
    }
}

@(private)
search_key :: proc(n: int, a: []int, key: int) -> int {
    low, high, mid: int

    /* invariant: a[lo] < key <= a[hi] */
    low = -1
    high = n

    for low + 1 < high {
        mid = (low+high)/2
        if a[mid] == key {
            return mid
        }

        if a[mid] < key {
            low = mid
            continue
        }

        high = mid
    }

    return high
}

@(private)
/* insert a new key into a tree */
/* returns new right sibling if the node splits */
/* and puts the median in *median */
/* else returns nil */
insert_key :: proc(b: BTree, key: int, median: ^int) -> BTree {
    output_log := false
    // output_log := key >= 525817
    if output_log {
        log.debugf("inserting key %d into %s", key, b.is_leaf ? "LEAF" : "ROOT")
    }
    median := median
    pos, mid: int
    b2: BTree

    pos = search_key(b.num_keys, b.keys[:], key)
    if output_log {
        log.debugf("found insertion position: %d", pos)
    }
    if pos < b.num_keys && b.keys[pos] == key {
        return nil
    }

    if b.is_leaf {
        /* everybody above pos moves up one space */
        copy_slice(b.keys[pos+1:], b.keys[pos:])
        b.keys[pos] = key
        b.num_keys += 1
    } else {
        /* insert in child */
        b2 = insert_key(b.kids[pos], key, &mid)

        /* maybe insert a new key in b */
        if b2 != nil {
            /* every key above pos moves up one space */
            copy_slice(b.keys[pos+1:], b.keys[pos:])
            /* new kid goes in pos + 1 */
            copy_slice(b.kids[pos+2:], b.kids[pos+1:])

            b.keys[pos] = mid
            b.kids[pos+1] = b2
            b.num_keys += 1
        }

        return b2
    }

    /* we waste a tiny bit of space by splitting now
     * instead of on next insert */
    if b.num_keys >= MAX_KEYS {
        if output_log {
            log.debug("CARRYING OUT SPLIT")
        }
        mid = b.num_keys/2

        median = &b.keys[mid]

        /* make a new node for keys > median */
        /* picture is:
        *
        *      3 5 7
        *      A B C D
        *
        * becomes
        *          (5)
        *      3        7
        *      A B      C D
        */
        b2 = new(BTNode)
        b2.num_keys = b.num_keys - mid - 1
        b2.is_leaf = b.is_leaf

        copy_slice(b2.keys[:], b.keys[mid+1:])
        if !b.is_leaf {
            copy_slice(b2.kids[:], b2.kids[mid+1:])
        }

        b.num_keys = mid

        return b2
    }

    return nil
}