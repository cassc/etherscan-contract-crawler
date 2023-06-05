// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/*//////////////////////////////////////////////////////////////////////////
                                Custom Errors
//////////////////////////////////////////////////////////////////////////*/

/// @dev blocked operator error
error BlockedOperator();

/// @dev unauthorized to call fn method
error Unauthorized();

/*//////////////////////////////////////////////////////////////////////////
                                IBlockList
//////////////////////////////////////////////////////////////////////////*/

/// @title IBlockList
/// @notice interface for the BlockList Contract
/// @author transientlabs.xyz
/// @custom:version 4.0.0
interface IBlockList {
    /// @notice function to get blocklist status with True meaning that the operator is blocked
    /// @dev must return false if the blocklist registry is an EOA or an incompatible contract, true/false if compatible
    /// @param operator - operator to check against for blocking
    function getBlockListStatus(address operator) external view returns (bool);
}