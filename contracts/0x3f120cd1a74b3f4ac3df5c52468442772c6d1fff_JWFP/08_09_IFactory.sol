//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}