// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

library UncheckedIncrement {
    function inc(uint256 i) internal pure returns (uint256) {
        unchecked { return  i + 1; }
    }
}