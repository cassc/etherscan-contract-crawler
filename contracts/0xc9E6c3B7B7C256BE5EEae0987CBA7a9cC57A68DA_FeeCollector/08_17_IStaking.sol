// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IStaking {
    function notifyRewardAmount(uint256 reward) external;
}