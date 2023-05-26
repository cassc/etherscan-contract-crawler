// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

/**
 * @title SafeUints
 * @notice Util functions which throws if a uint256 can't fit into smaller uints.
 */
contract SafeUints {
    // @dev Checks if the given uint256 does not overflow uint96
    function _safe96(uint256 n) internal pure returns (uint96) {
        require(n < 2**96, "VPools: Unsafe96");
        return uint96(n);
    }
}