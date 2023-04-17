// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

interface ISwapGetAmounts {
    function getAmountsIn(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}