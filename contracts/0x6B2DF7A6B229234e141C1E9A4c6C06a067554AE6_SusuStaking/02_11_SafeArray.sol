// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Array
 * @dev Array remove element
 */
library SafeArray {
    function removeElement(uint256[] storage _array, uint256 _element)
        internal
    {
        for (uint256 i; i < _array.length; i++) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }
}