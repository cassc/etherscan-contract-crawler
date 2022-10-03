// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/DoubleEndedQueue.sol)
pragma solidity ^0.8.4;

import 'openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

/**
 * @notice Modified version of Open Zeppelin's DoubleEndedQueue, but using `DebtEntry` instead of `bytes32` for the values in the queue
 * DoubleEndedQueue: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/utils/structs/DoubleEndedQueue.sol
 * The purpose of the queue is to keep track of accounts holding debt and their order
 * @dev The queue is intended to be used only as FIFO, so the functions `popBack`, `pushFront`, `back`, `clear` were removed
 */
library DebtQueue {
    /**
     * @dev An operation (e.g. {front}) couldn't be completed due to the queue being empty.
     */
    error Empty();

    /**
     * @dev An operation (e.g. {at}) couldn't be completed due to an index being out of bounds.
     */
    error OutOfBounds();

    struct DebtEntry {
        address account;
        uint96 amount;
    }

    /**
     * @dev Indices are signed integers because the queue can grow in any direction. They are 128 bits so begin and end
     * are packed in a single storage slot for efficient access. Since the items are added one at a time we can safely
     * assume that these 128-bit indices will not overflow, and use unchecked arithmetic.
     *
     * Struct members have an underscore prefix indicating that they are "private" and should not be read or written to
     * directly. Use the functions provided below instead. Modifying the struct manually may violate assumptions and
     * lead to unexpected behavior.
     *
     * Indices are in the range [begin, end) which means the first item is at data[begin] and the last item is at
     * data[end - 1].
     */
    struct DebtDeque {
        int128 _begin;
        int128 _end;
        mapping(int128 => DebtEntry) _data;
    }

    /**
     * @dev Inserts an item at the end of the queue.
     */
    function pushBack(DebtDeque storage deque, DebtEntry memory debtEntry) internal {
        int128 backIndex = deque._end;
        deque._data[backIndex] = debtEntry;
        unchecked {
            deque._end = backIndex + 1;
        }
    }

    /**
     * @dev Removes the item at the beginning of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popFront(DebtDeque storage deque) internal returns (DebtEntry memory value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        value = deque._data[frontIndex];
        delete deque._data[frontIndex];
        unchecked {
            deque._begin = frontIndex + 1;
        }
    }

    /**
     * @dev Returns the item at the beginning of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function front(DebtDeque storage deque) internal view returns (DebtEntry storage value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        return deque._data[frontIndex];
    }

    /**
     * @dev Return the item at a position in the queue given by `index`, with the first item at 0 and last item at
     * `length(deque) - 1`.
     *
     * Reverts with `OutOfBounds` if the index is out of bounds.
     */
    function at(DebtDeque storage deque, uint256 index) internal view returns (DebtEntry storage value) {
        // int256(deque._begin) is a safe upcast
        int128 idx = SafeCast.toInt128(int256(deque._begin) + SafeCast.toInt256(index));
        if (idx >= deque._end) revert OutOfBounds();
        return deque._data[idx];
    }

    /**
     * @dev Returns the number of items in the queue.
     */
    function length(DebtDeque storage deque) internal view returns (uint256) {
        // The interface preserves the invariant that begin <= end so we assume this will not overflow.
        // We also assume there are at most int256.max items in the queue.
        unchecked {
            return uint256(int256(deque._end) - int256(deque._begin));
        }
    }

    /**
     * @dev Returns true if the queue is empty.
     */
    function empty(DebtDeque storage deque) internal view returns (bool) {
        return deque._end <= deque._begin;
    }
}