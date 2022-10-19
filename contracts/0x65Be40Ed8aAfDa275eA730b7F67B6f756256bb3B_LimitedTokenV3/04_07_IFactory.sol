//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}