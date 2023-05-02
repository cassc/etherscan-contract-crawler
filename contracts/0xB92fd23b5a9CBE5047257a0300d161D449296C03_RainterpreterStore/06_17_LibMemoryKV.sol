// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "sol.lib.binmaskflag/Binary.sol";

/// Thrown when attempting to read a value from the other side of a zero pointer.
error InvalidPtr(MemoryKVPtr ptr);

/// Entrypoint into the key/value store. Is a mutable pointer to the head of the
/// linked list. Initially points to `0` for an empty list. The total length of
/// the linked list is also encoded alongside the pointer to allow efficient O(1)
/// memory allocation for a `uint256[]` in the case of a final snapshot/export.
type MemoryKV is uint256;
/// The key associated with the value for each item in the linked list.
type MemoryKVKey is uint256;
/// The pointer to the next item in the list. `0` signifies the end of the list.
type MemoryKVPtr is uint256;
/// The value associated with the key for each item in the linked list.
type MemoryKVVal is uint256;

/// @title LibMemoryKV
/// @notice Implements an in-memory key/value store in terms of a linked list
/// that can be snapshotted/exported to a `uint256[]` of pairwise keys/values as
/// its items. Ostensibly supports reading/writing to storage within a read only
/// context in an interpreter `eval` by tracking changes requested by an
/// expression in memory as a cache-like structure over the underlying storage.
///
/// A linked list is required because unlike stack movements we do NOT have any
/// way to precalculate how many items will be included in the final set at
/// deploy time. Any two writes may share the same key known only at runtime, so
/// any two writes may result in either 2 or 1 insertions (and 0 or 1 updates).
/// We could attempt to solve this by allowing duplicate keys and simply append
/// values for each write, so two writes will always insert 2 values, but then
/// looping constructs such as `OpDoWhile` and `OpFoldContext` with net 0 stack
/// movements (i.e. predictably deallocateable memory) can still cause
/// unbounded/unknown inserts for our state changes. The linked list allows us
/// to both dedupe same-key writes and also safely handle an unknown
/// (at deploy time) number of upserts. New items are inserted at the head of
/// the list and a pointer to `0` is the sentinel that defines the end of the
/// list. It is an error to dereference the `0` pointer.
///
/// Currently implemented as O(n) where n is likely relatively small, in future
/// could be reimplemented as 8 linked lists over a single `MemoryKV` by packing
/// many `MemoryKVPtr` and using `%` to distribute keys between lists. The
/// extremely high gas cost of writing to storage itself should be a natural
/// disincentive for n getting large enough to cause the linked list traversal
/// to be a significant gas cost itself.
///
/// Currently implemented in terms of raw `uint256` custom types that represent
/// keys, values and pointers. Could be reimplemented in terms of an equivalent
/// struct with key, value and pointer fields.
library LibMemoryKV {
    /// Reads the `MemoryKVVal` that some `MemoryKVPtr` is pointing to. It is an
    /// error to call this if `ptr_` is `0`.
    /// @param ptr_ The pointer to read the value
    function readPtrVal(
        MemoryKVPtr ptr_
    ) internal pure returns (MemoryKVVal v_) {
        // This is ALWAYS a bug. It means the caller did not check if the ptr is
        // nonzero before trying to read from it.
        if (MemoryKVPtr.unwrap(ptr_) == 0) {
            revert InvalidPtr(ptr_);
        }

        assembly ("memory-safe") {
            v_ := mload(add(ptr_, 0x20))
        }
    }

    /// Finds the pointer to the item that holds the value associated with the
    /// given key. Walks the linked list from the entrypoint into the key/value
    /// store until it finds the specified key. As the last pointer in the list
    /// is always `0`, `0` is what will be returned if the key is not found. Any
    /// non-zero pointer implies the value it points to is for the provided key.
    /// @param kv_ The entrypoint to the key/value store.
    /// @param k_ The key to lookup a pointer for.
    /// @return ptr_ The _pointer_ to the value for the key, if it exists, else
    /// a pointer to `0`. If the pointer is non-zero the associated value can be
    /// read to a `MemoryKVVal` with `LibMemoryKV.readPtrVal`.
    function getPtr(
        MemoryKV kv_,
        MemoryKVKey k_
    ) internal pure returns (MemoryKVPtr ptr_) {
        uint256 mask_ = MASK_16BIT;
        assembly ("memory-safe") {
            // loop until k found or give up if ptr is zero
            for {
                ptr_ := and(kv_, mask_)
            } iszero(iszero(ptr_)) {
                ptr_ := mload(add(ptr_, 0x40))
            } {
                if eq(k_, mload(ptr_)) {
                    break
                }
            }
        }
    }

    /// Upserts a value in the set by its key. I.e. if the key exists then the
    /// associated value will be mutated in place, else a new key/value pair will
    /// be inserted. The key/value store pointer will be mutated and returned as
    /// it MAY point to a new list item in memory.
    /// @param kv_ The key/value store pointer to modify.
    /// @param k_ The key to upsert against.
    /// @param v_ The value to associate with the upserted key.
    /// @return The final value of `kv_` as it MAY be modified if the upsert
    /// resulted in an insert operation.
    function setVal(
        MemoryKV kv_,
        MemoryKVKey k_,
        MemoryKVVal v_
    ) internal pure returns (MemoryKV) {
        MemoryKVPtr ptr_ = getPtr(kv_, k_);
        uint256 mask_ = MASK_16BIT;
        // update
        if (MemoryKVPtr.unwrap(ptr_) > 0) {
            assembly ("memory-safe") {
                mstore(add(ptr_, 0x20), v_)
            }
        }
        // insert
        else {
            assembly ("memory-safe") {
                // allocate new memory
                ptr_ := mload(0x40)
                mstore(0x40, add(ptr_, 0x60))
                // set k/v/ptr
                mstore(ptr_, k_)
                mstore(add(ptr_, 0x20), v_)
                mstore(add(ptr_, 0x40), and(kv_, mask_))
                // kv must point to new insertion and update array len
                kv_ := or(
                    // inc len by 2
                    shl(16, add(shr(16, kv_), 2)),
                    // set ptr
                    ptr_
                )
            }
        }
        return kv_;
    }

    /// Export/snapshot the underlying linked list of the key/value store into
    /// a standard `uint256[]`. Reads the total length to preallocate the
    /// `uint256[]` then walks the entire linked list, copying every key and
    /// value into the array, until it reaches a pointer to `0`. Note this is a
    /// one time export, if the key/value store is subsequently mutated the built
    /// array will not reflect these mutations.
    /// @param kv_ The entrypoint into the key/value store.
    /// @return All the keys and values copied pairwise into a `uint256[]`.
    function toUint256Array(
        MemoryKV kv_
    ) internal pure returns (uint256[] memory) {
        unchecked {
            uint256 ptr_ = MemoryKV.unwrap(kv_) & MASK_16BIT;
            uint256 length_ = MemoryKV.unwrap(kv_) >> 16;
            uint256[] memory arr_ = new uint256[](length_);
            assembly ("memory-safe") {
                for {
                    let cursor_ := add(arr_, 0x20)
                    let end_ := add(cursor_, mul(mload(arr_), 0x20))
                } lt(cursor_, end_) {
                    cursor_ := add(cursor_, 0x20)
                    ptr_ := mload(add(ptr_, 0x40))
                } {
                    // key
                    mstore(cursor_, mload(ptr_))
                    cursor_ := add(cursor_, 0x20)
                    // value
                    mstore(cursor_, mload(add(ptr_, 0x20)))
                }
            }
            return arr_;
        }
    }
}