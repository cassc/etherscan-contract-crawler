//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @title Sorter
    @author iMe Group
    @notice Small sorting library
 */
library Sorter {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}