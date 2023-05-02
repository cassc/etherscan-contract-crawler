// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface UniswapRouterInterfaceV5{
	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapTokensForExactTokens(
		uint amountOut,
		uint amountInMax,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);
	function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
	function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
}