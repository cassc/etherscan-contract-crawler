// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev Singleton operations.
 */
library Singleton {
    function _asSingletonArray(uint256 element)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}