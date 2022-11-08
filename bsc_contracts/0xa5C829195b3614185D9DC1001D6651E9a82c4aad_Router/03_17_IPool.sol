// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IPool {
    function COLLATERAL_TOKEN() external view returns (address);
    function LOGIC() external view returns (address);
	function swap(
        address tokenIn,
        address tokenOut,
        address recipient
    ) external returns (uint amountOut, uint fee);
    // TODO: flashSwap
}