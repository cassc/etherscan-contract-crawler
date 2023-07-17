//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}