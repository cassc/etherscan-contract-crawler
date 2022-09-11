// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}