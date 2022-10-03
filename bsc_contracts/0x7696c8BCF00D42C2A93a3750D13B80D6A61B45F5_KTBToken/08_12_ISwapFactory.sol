// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface ISwapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
