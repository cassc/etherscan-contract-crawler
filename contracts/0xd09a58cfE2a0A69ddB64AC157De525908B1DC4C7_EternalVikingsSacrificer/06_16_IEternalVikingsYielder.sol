// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IEternalVikingsYielder {
    function registerShadowEarnings(address user) external;
    function rewardGold(address to, uint256 amount) external;
}