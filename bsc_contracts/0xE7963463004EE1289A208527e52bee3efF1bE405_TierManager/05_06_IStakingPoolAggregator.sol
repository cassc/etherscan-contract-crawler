// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IStakingPoolAggregator {
    function checkForStakedRequirements(address, uint256, uint256) external view returns (bool);
}