// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExchange {
    function swapStETH(uint256 amount) external;

    function swapETH(uint256 amount) external;

    function swapExactETH(uint256 input, uint256 output) external;
}