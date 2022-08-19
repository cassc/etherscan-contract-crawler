pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}