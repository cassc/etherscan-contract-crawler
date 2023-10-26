// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IUniswapV2Factory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}