// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { MinHeap } from "../lib/MinHeap.sol";

contract HeapTest {
    using MinHeap for MinHeap.Heap;

    MinHeap.Heap internal _heap;

    function size()
        external
        view
        returns (uint256)
    {
        return _heap.length;
    }

    function insert(
        uint256 value
    )
        external
    {
        _heap.insert(value);
    }

    function insertMany(
        uint256[] calldata values
    )
        external
    {
        for (uint256 i = 0; i < values.length; i++) {
            _heap.insert(values[i]);
        }
    }

    function peek()
        external
        view
        returns (uint256)
    {
        return _heap.safePeek();
    }

    function pop()
        external
    {
        _heap.popMin();
    }

    function popMany(
        uint256 count
    )
        external
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = _heap.safePeek();
            _heap.popMin();
        }
        return result;
    }

    function heap(
        uint256 index
    )
        external
        view
        returns (uint256)
    {
        return _heap.data[index];
    }

    function read(
        uint256 start,
        uint256 end
    )
        public
        view
        returns (uint256[] memory)
    {
        uint256 length = end - start;
        uint256[] memory result = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = _heap.data[start + i];
        }
        return result;
    }

    function readAll()
        external
        view
        returns (uint256[] memory)
    {
        return read(0, _heap.length);
    }
}