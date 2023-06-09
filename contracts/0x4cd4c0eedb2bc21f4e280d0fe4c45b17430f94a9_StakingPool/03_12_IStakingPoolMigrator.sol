// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IStakingPoolMigrator {
    function stakingPoolV1Balance() external view returns (uint256);

    function calculatePriceParams()
        external
        view
        returns (uint256 stakingPoolV1Balance_, uint256 burnedSyntheticAmount);

    function update() external returns (bool success);
}