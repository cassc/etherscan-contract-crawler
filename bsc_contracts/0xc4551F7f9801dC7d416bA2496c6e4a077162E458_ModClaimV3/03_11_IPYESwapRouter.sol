// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IPYESwapRouter {
    function getAmountsIn(uint amountOut, address[] memory path, uint totalFee) external view returns (uint[] memory amounts);
}