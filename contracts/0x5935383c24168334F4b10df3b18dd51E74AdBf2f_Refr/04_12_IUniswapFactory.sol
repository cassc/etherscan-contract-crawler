// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.9;

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}