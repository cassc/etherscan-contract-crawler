// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// https://etherscan.io/address/0xd9e1ce17f2641f24ae83637ab66a2cca9c378b9f
// it's actually a UniswapV2Router02 but renamed for clarity vs actual uniswap

interface ISushiRouter {
	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);
}