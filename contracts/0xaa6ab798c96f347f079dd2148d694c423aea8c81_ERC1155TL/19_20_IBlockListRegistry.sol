// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title BlockList Registry
/// @notice interface for the BlockListRegistry Contract
/// @author transientlabs.xyz
/// @custom:version 4.0.0
interface IBlockListRegistry {
    /*//////////////////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////////////////*/

    event BlockListStatusChange(address indexed user, address indexed operator, bool indexed status);

    event BlockListCleared(address indexed user);

    /*//////////////////////////////////////////////////////////////////////////
                          Public Read Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to get blocklist status with True meaning that the operator is blocked
    function getBlockListStatus(address operator) external view returns (bool);

    /*//////////////////////////////////////////////////////////////////////////
                          Public Write Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to set the block list status for multiple operators
    /// @dev must be called by the blockList owner
    function setBlockListStatus(address[] calldata operators, bool status) external;

    /// @notice function to clear the block list status
    /// @dev must be called by the blockList owner
    function clearBlockList() external;
}