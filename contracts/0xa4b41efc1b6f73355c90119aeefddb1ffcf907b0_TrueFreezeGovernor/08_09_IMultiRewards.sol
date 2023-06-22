//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IMultiRewards {
    function notifyRewardAmount(address, uint256) external;
}