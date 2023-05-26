// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ISwapRewards {
    function swap(address user, address tokenIn, uint256 amountIn) external;
}