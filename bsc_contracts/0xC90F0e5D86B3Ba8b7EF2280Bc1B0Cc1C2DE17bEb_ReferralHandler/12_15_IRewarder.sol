// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IRewarder {
    function handleReward(uint256 claimedEpoch, address factory, address token) external;
}