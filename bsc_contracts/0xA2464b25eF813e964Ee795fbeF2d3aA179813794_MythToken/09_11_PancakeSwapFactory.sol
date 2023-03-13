// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface PancakeSwapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}