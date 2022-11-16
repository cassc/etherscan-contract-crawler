//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// https://github.com/Uniswap/swap-router-contracts/blob/main/contracts/interfaces/ISwapRouter02.sol

interface ISwapRouter02 {
	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to
	) external payable returns (uint256 amountOut);

	struct ExactInputSingleParams {
		address tokenIn;
		address tokenOut;
		uint24 fee;
		address recipient;
		uint256 amountIn;
		uint256 amountOutMinimum;
		uint160 sqrtPriceLimitX96;
	}

	/// @notice Swaps `amountIn` of one token for as much as possible of another token
	/// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
	/// and swap the entire amount, enabling contracts to send tokens before calling this function.
	/// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
	/// @return amountOut The amount of the received token
	function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

	struct ExactInputParams {
		bytes path;
		address recipient;
		uint256 amountIn;
		uint256 amountOutMinimum;
	}

	/// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
	/// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
	/// and swap the entire amount, enabling contracts to send tokens before calling this function.
	/// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
	/// @return amountOut The amount of the received token
	function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}