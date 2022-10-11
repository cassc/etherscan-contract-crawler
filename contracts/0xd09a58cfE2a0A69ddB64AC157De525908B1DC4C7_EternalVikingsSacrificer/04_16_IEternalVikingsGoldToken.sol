// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IEternalVikingsGoldToken {
    function reward(address to, uint256 amount) external;
    function consume(address from, uint256 amount) external;
}