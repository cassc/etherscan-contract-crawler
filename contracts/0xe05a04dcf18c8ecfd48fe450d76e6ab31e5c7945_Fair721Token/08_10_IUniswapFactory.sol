// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}