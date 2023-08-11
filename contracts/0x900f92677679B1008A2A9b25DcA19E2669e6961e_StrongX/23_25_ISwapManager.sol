// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISwapManager {
    function swapToWeth(uint tokenAmount) external;
    function addLiquidity(uint tokenAmount, uint wethAmount) external;
}