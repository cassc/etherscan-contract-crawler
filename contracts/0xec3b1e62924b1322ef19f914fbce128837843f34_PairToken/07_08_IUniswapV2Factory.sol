// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.11;

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}