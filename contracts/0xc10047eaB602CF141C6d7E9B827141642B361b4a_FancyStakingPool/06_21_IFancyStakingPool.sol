// SPDX-License-Identifier: MIT
// Forked from Merit Circle
pragma solidity 0.8.7;

interface IFancyStakingPool {
    function deposit(
        uint256 _amount,
        uint256 _duration,
        address _receiver
    ) external;
}