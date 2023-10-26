// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExchange {
    function swapStETH(address token,uint256 amount,uint256 minAmount) external;

    function swapETH(address token,uint256 amount,uint256 minAmount) external;

    //function swapExactETH(uint256 input, uint256 output) external;
}