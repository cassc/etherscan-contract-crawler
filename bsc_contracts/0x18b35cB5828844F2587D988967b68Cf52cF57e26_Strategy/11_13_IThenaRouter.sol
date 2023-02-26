pragma solidity >=0.6.2;
pragma experimental ABIEncoderV2;

struct route {
	address from;
	address to;
	bool stable;
}

interface IThenaRouter {
	function getAmountOut(
		uint256 amountIn,
		address tokenIn,
		address tokenOut
	) external view returns (uint256 amount, bool stable);

	function quoteAddLiquidity(
		address tokenA,
		address tokenB,
		bool stable,
		uint256 amountADesired,
		uint256 amountBDesired
	)
		external
		view
		returns (
			uint256 amountA,
			uint256 amountB,
			uint256 liquidity
		);

	function quoteRemoveLiquidity(
		address tokenA,
		address tokenB,
		bool stable,
		uint256 liquidity
	) external view returns (uint256 amountA, uint256 amountB);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		route[] calldata routes,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function addLiquidity(
		address tokenA,
		address tokenB,
		bool stable,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	)
		external
		returns (
			uint256 amountA,
			uint256 amountB,
			uint256 liquidity
		);

	function removeLiquidity(
		address tokenA,
		address tokenB,
		bool stable,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);
}