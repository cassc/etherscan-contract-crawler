// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract Utils {
    /// @notice A helper function to work with unchecked iterators in loops.
    function uncheckedInc(uint256 i) internal pure returns (uint256 j) {
        unchecked {
            j = i + 1;
        }
    }
}