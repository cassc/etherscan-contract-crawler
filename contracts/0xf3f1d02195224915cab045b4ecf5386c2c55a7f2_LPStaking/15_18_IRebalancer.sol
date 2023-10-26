// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IRebalancer {
    function rebalance(uint16 callerRewardDivisor, uint16 rebalanceDivisor) external;
    function refill() payable external;
}