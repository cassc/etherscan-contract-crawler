// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IkaniV2Staking
 * @author Cyborg Labs, LLC
 *
 * @dev Priority queue implemented as a heap.
 */
library MinHeap {

    struct Heap {
        mapping(uint256 => uint256) data;
        uint256 length;
    }

    function insert(
        Heap storage _heap_,
        uint256 value
    )
        internal
    {
        unchecked {
            uint256 index = _heap_.length + 1;
            _heap_.length = index;

            while (index != 1) {
                uint256 parentIndex = index >> 1;
                uint256 parentValue = _heap_.data[parentIndex];
                if (parentValue <= value) {
                    break;
                }
                _heap_.data[index] = parentValue;
                index = parentIndex;
            }

            _heap_.data[index] = value;
        }
    }

    function unsafePeek(
        Heap storage _heap_
    )
        internal
        view
        returns (uint256)
    {
        return _heap_.data[1];
    }

    function safePeek(
        Heap storage _heap_
    )
        internal
        view
        returns (uint256)
    {
        require(
            _heap_.length != 0,
            "Heap is empty"
        );
        return _heap_.data[1];
    }

    function popMin(
        Heap storage _heap_
    )
        internal
    {
        unchecked {
            // We implicitly move the last value to the top of the heap, and heapify it down.
            uint256 oldLength = _heap_.length--;
            uint256 lastValue = _heap_.data[oldLength];

            if (oldLength == 1) {
                return;
            }

            uint256 index = 1;
            uint256 leftChildIndex = 2;
            uint256 rightChildIndex = 3;

            // While there is a left child...
            while (leftChildIndex < oldLength) {

                // Get the smaller of the left child and (if it exists) the right child.
                uint256 childIndex = leftChildIndex;
                uint256 childValue = _heap_.data[leftChildIndex];
                if (rightChildIndex < oldLength) {
                    uint256 rightChildValue = _heap_.data[rightChildIndex];
                    if (rightChildValue < childValue) {
                        childIndex = rightChildIndex;
                        childValue = rightChildValue;
                    }
                }

                // If the child value is smaller than our value, bring the child up.
                if (childValue < lastValue) {
                    _heap_.data[index] = childValue;
                    index = childIndex;
                } else {
                    break;
                }

                leftChildIndex = index << 1;
                rightChildIndex = leftChildIndex + 1;
            }

            _heap_.data[index] = lastValue;
        }
    }
}