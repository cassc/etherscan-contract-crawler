// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Types.sol";

library ArrayFind {
    function find(
        uint256[] memory arr,
        uint value
    ) internal pure returns (uint256) {
        uint256 ind = IndexNotFound;
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == value) {
                ind = i;
                break;
            }
        }

        return ind;
    }

    function find(
        bytes32[] memory arr,
        bytes32 value
    ) internal pure returns (uint256) {
        uint256 ind = IndexNotFound;
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == value) {
                ind = i;
                break;
            }
        }

        return ind;
    }

    function find(
        address[] memory arr,
        address value
    ) internal pure returns (uint256) {
        uint256 ind = IndexNotFound;
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == value) {
                ind = i;
                break;
            }
        }

        return ind;
    }

    function exist(
        address[] memory arr,
        address value
    ) internal pure returns (bool) {
        return find(arr, value) != IndexNotFound;
    }

    function checkForDublicates(
        address[] memory arr
    ) internal pure returns (bool) {
        for (uint i = 0; i < arr.length; i++) {
            address _val = arr[i];

            for (uint j = i + 1; j < arr.length; j++) {
                if (arr[j] == _val) return true;
            }
        }

        return false;
    }
}