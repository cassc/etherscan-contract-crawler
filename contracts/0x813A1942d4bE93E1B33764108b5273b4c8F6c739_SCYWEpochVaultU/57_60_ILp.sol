// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

abstract contract ILp {
	function _quote(
		uint256 amount,
		address token0,
		address token1
	) internal view virtual returns (uint256 price);

	function _getLiquidity() internal view virtual returns (uint256);

	function _getLiquidity(uint256) internal view virtual returns (uint256);

	function _addLiquidity(uint256 amountToken0, uint256 amountToken1)
		internal
		virtual
		returns (uint256 liquidity);

	function _removeLiquidity(uint256 liquidity) internal virtual returns (uint256, uint256);

	function _getLPBalances()
		internal
		view
		virtual
		returns (uint256 underlyingBalance, uint256 shortBalance);
}