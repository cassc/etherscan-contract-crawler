// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IStakingPoolMigrator {
    function migrate(
        uint256 poolId,
        address oldToken,
        uint256 amount
    ) external returns (address);
}