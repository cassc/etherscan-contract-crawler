// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// A simple array that supports insert and removal.
// The values are assumed to be unique and the library is meant to be lightweight.
// So when calling insert or remove, the caller is responsible to know whether a value already exists in the array or not.
library FastArray {
    struct Data {
        mapping(uint256 => uint256) array;
        mapping(uint256 => uint256) indexMap;
        uint256 length;
    }

    /**
     * @notice please confirm no eq item exist before insert
     */
    function insert(Data storage _fastArray, uint256 _value) internal {
        _fastArray.array[_fastArray.length] = _value;
        _fastArray.indexMap[_value] = _fastArray.length;
        _fastArray.length += 1;
    }

    /**
     * @dev remove item from array,but not keep rest item sort
     * @notice Please confirm array is not empty && item is exist && index not out of bounds
     */
    function remove(Data storage _fastArray, uint256 _value) internal {
        uint256 index = _fastArray.indexMap[_value];

        _fastArray.array[index] = _fastArray.array[_fastArray.length - 1];
        delete _fastArray.indexMap[_value];
        delete _fastArray.array[_fastArray.length - 1];

        _fastArray.length -= 1;
    }

    /**
     * @dev remove item and keep rest item in sort
     * @notice Please confirm array is not empty && item is exist && index not out of bounds
     */
    function removeKeepSort(Data storage _fastArray, uint256 _value) internal {
        uint256 index = _fastArray.indexMap[_value];

        uint256 tempLastItem = _fastArray.array[_fastArray.length - 1];

        for (uint256 i = index; i < _fastArray.length - 1; i++) {
            _fastArray.indexMap[_fastArray.array[i + 1]] = i;
            _fastArray.array[i] = _fastArray.array[i + 1];
        }

        delete _fastArray.indexMap[tempLastItem];
        delete _fastArray.array[_fastArray.length - 1];
        _fastArray.length -= 1;
    }

    /**
     * @notice PLease confirm index is not out of bounds
     */
    function get(
        Data storage _fastArray,
        uint256 _index
    ) public view returns (uint256) {
        return _fastArray.array[_index];
    }

    function length(Data storage _fastArray) public view returns (uint256) {
        return _fastArray.length;
    }

    function contains(
        Data storage _fastArray,
        uint256 _value
    ) public view returns (bool) {
        return _fastArray.indexMap[_value] != 0;
    }
}