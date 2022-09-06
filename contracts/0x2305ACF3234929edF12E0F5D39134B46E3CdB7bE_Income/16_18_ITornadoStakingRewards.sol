// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITornadoStakingRewards {
    function getReward() external;

    function checkReward(address account) external view returns (uint256 rewards);
}