pragma solidity >=0.5.0;
// SPDX-License-Identifier: MIT
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}