// SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.7.4;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}