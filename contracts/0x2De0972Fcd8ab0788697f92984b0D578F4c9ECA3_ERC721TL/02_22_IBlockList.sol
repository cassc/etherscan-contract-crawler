// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.17;

/*//////////////////////////////////////////////////////////////////////////
                                Custom Errors
//////////////////////////////////////////////////////////////////////////*/

/// @dev blocked operator error
error BlockedOperator();

/// @dev unauthorized to call fn method
error Unauthorized();

interface IBlockList {
    /// @notice function to get blocklist status with True meaning that the operator is blocked
    /// @dev must return false if the blocklist registry is an EOA or an incompatible contract, true/false if compatible
    /// @param operator - operator to check against for blocking
    function getBlockListStatus(address operator) external view returns (bool);
}