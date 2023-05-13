// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IReward {
    function releaseReward(address paymentToken, address[] calldata users, uint256[] calldata rewards) external;
}