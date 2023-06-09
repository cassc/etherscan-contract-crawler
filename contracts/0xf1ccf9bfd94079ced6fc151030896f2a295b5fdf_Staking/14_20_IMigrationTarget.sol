// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IMigrationTarget {
    /// @notice This function allows stakers to migrate funds from an old staking pool.
    /// @param amount Amount of tokens to migrate
    /// @param data Migration path details
    function migrateFrom(uint256 amount, bytes calldata data) external;
}