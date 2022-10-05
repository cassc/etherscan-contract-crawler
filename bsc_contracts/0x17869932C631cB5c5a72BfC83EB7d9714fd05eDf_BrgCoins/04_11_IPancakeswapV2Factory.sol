// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPancakeswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}