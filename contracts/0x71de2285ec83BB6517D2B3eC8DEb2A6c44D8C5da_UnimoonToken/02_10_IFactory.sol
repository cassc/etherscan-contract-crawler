// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}