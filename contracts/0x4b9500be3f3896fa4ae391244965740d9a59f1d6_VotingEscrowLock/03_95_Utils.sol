//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

library Utils {
    function find(address[] memory arr, address item)
        internal
        pure
        returns (bool exist, uint256 index)
    {
        for (uint256 i = 0; i < arr.length; i += 1) {
            if (arr[i] == item) {
                return (true, i);
            }
        }
    }

    function find(bytes4[] memory arr, bytes4 sig)
        internal
        pure
        returns (bool exist, uint256 index)
    {
        for (uint256 i = 0; i < arr.length; i += 1) {
            if (arr[i] == sig) {
                return (true, i);
            }
        }
    }
}